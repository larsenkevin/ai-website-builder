import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fc from 'fast-check';
import { AssetProcessor } from '../../app/services/AssetProcessor.js';
import { Logger } from '../../app/services/Logger.js';
import { UploadedFile } from '../../app/types/asset.js';
import fs from 'fs/promises';
import path from 'path';
import sharp from 'sharp';

/**
 * Property-Based Tests for Asset Processing
 * 
 * These tests validate the AssetProcessor service's behavior across
 * a wide range of inputs using property-based testing.
 */

describe('Asset Processing Property Tests', () => {
  const testUploadsDir = './test-uploads-property';
  const testProcessedDir = './test-processed-property';
  const testPublicDir = './test-public-property';
  
  let assetProcessor: AssetProcessor;
  let logger: Logger;

  beforeEach(async () => {
    // Create test directories
    await fs.mkdir(testUploadsDir, { recursive: true });
    await fs.mkdir(testProcessedDir, { recursive: true });
    await fs.mkdir(testPublicDir, { recursive: true });

    // Initialize logger
    logger = new Logger({
      logDir: './test-logs-property',
      level: 'error', // Reduce noise during tests
      maxFileSize: 10 * 1024 * 1024,
      retentionDays: 1,
    });

    // Initialize asset processor
    assetProcessor = new AssetProcessor(
      {
        uploadsDir: testUploadsDir,
        processedDir: testProcessedDir,
        publicDir: testPublicDir,
        maxFileSize: 5 * 1024 * 1024, // 5MB
        sizes: [320, 768, 1920],
        webpQuality: 85,
      },
      logger
    );
  });

  afterEach(async () => {
    // Cleanup test directories
    try {
      await fs.rm(testUploadsDir, { recursive: true, force: true });
      await fs.rm(testProcessedDir, { recursive: true, force: true });
      await fs.rm(testPublicDir, { recursive: true, force: true });
      await fs.rm('./test-logs-property', { recursive: true, force: true });
    } catch (error) {
      // Ignore cleanup errors
    }
  });

  /**
   * Helper function to create a test image buffer
   */
  async function createTestImage(
    width: number,
    height: number,
    format: 'jpeg' | 'png' | 'gif'
  ): Promise<Buffer> {
    const sharpInstance = sharp({
      create: {
        width,
        height,
        channels: 3,
        background: { r: 255, g: 0, b: 0 },
      },
    });

    if (format === 'jpeg') {
      return await sharpInstance.jpeg().toBuffer();
    } else if (format === 'png') {
      return await sharpInstance.png().toBuffer();
    } else {
      return await sharpInstance.gif().toBuffer();
    }
  }

  /**
   * Helper function to create a mock UploadedFile
   */
  function createMockFile(
    name: string,
    data: Buffer,
    mimetype: string
  ): UploadedFile {
    return {
      name,
      data,
      size: data.length,
      mimetype,
      mv: async (targetPath: string) => {
        await fs.writeFile(targetPath, data);
      },
    };
  }

  /**
   * Property 19: Image Format Validation
   * 
   * Validate that only JPEG, PNG, GIF formats are accepted.
   * 
   * **Validates: Requirements 13.1, 13.2**
   */
  describe('Property 19: Image Format Validation', () => {
    it('Property: Valid image formats are accepted', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.constantFrom('jpeg', 'png', 'gif'),
          fc.integer({ min: 100, max: 500 }),
          fc.integer({ min: 100, max: 500 }),
          async (format, width, height) => {
            const buffer = await createTestImage(width, height, format);
            const mimetypeMap = {
              jpeg: 'image/jpeg',
              png: 'image/png',
              gif: 'image/gif',
            };
            const mimetype = mimetypeMap[format];
            const file = createMockFile(`test.${format}`, buffer, mimetype);

            // Should not throw
            const result = await assetProcessor.processImage(file, 'Test image');
            expect(result).toBeDefined();
            expect(result.mimetype).toBe(mimetype);
          }
        ),
        { numRuns: 10 }
      );
    });

    it('Property: Invalid image formats are rejected', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.constantFrom('image/bmp', 'image/tiff', 'image/webp', 'application/pdf', 'text/plain'),
          async (invalidMimetype) => {
            const buffer = Buffer.from('fake image data');
            const file = createMockFile('test.fake', buffer, invalidMimetype);

            // Should throw an error
            await expect(assetProcessor.processImage(file, 'Test')).rejects.toThrow(
              /Invalid image format/
            );
          }
        ),
        { numRuns: 5 }
      );
    });

    it('Property: isValidImageFormat correctly identifies valid formats', async () => {
      await fc.assert(
        fc.property(
          fc.constantFrom('image/jpeg', 'image/png', 'image/gif'),
          (mimetype) => {
            expect(assetProcessor.isValidImageFormat(mimetype)).toBe(true);
          }
        ),
        { numRuns: 10 }
      );
    });

    it('Property: isValidImageFormat correctly rejects invalid formats', async () => {
      await fc.assert(
        fc.property(
          fc.constantFrom('image/bmp', 'image/tiff', 'image/webp', 'application/pdf'),
          (mimetype) => {
            expect(assetProcessor.isValidImageFormat(mimetype)).toBe(false);
          }
        ),
        { numRuns: 10 }
      );
    });
  });

  /**
   * Property 20: Image Size Validation
   * 
   * Validate that files exceeding 5MB are rejected.
   * 
   * **Validates: Requirements 13.4**
   */
  describe('Property 20: Image Size Validation', () => {
    it('Property: Files under 5MB are accepted', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 1, max: 5 * 1024 * 1024 }), // Up to 5MB
          fc.constantFrom('jpeg', 'png', 'gif'),
          async (targetSize, format) => {
            // Create a small image and pad it to reach target size
            const baseBuffer = await createTestImage(100, 100, format);
            const padding = Buffer.alloc(Math.max(0, targetSize - baseBuffer.length));
            const buffer = Buffer.concat([baseBuffer, padding]);
            
            const mimetypeMap = {
              jpeg: 'image/jpeg',
              png: 'image/png',
              gif: 'image/gif',
            };
            const file = createMockFile(`test.${format}`, buffer, mimetypeMap[format]);

            // Should not throw
            const result = await assetProcessor.processImage(file, 'Test image');
            expect(result).toBeDefined();
            expect(result.size).toBeLessThanOrEqual(5 * 1024 * 1024);
          }
        ),
        { numRuns: 5 }
      );
    });

    it('Property: Files exceeding 5MB are rejected', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 5 * 1024 * 1024 + 1, max: 10 * 1024 * 1024 }), // Over 5MB
          async (size) => {
            const buffer = Buffer.alloc(size);
            const file = createMockFile('test.jpg', buffer, 'image/jpeg');

            // Should throw an error
            await expect(assetProcessor.processImage(file, 'Test')).rejects.toThrow(
              /exceeds.*5MB/i
            );
          }
        ),
        { numRuns: 5 }
      );
    });
  });

  /**
   * Property 21: Unique Filename Generation
   * 
   * Ensure all generated filenames are unique (UUID-based).
   * 
   * **Validates: Requirements 13.5**
   */
  describe('Property 21: Unique Filename Generation', () => {
    it('Property: Multiple uploads generate unique IDs', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 2, max: 10 }),
          async (numUploads) => {
            const ids = new Set<string>();
            
            for (let i = 0; i < numUploads; i++) {
              const buffer = await createTestImage(100, 100, 'jpeg');
              const file = createMockFile(`test${i}.jpg`, buffer, 'image/jpeg');
              const result = await assetProcessor.processImage(file, `Test ${i}`);
              
              // ID should be unique
              expect(ids.has(result.id)).toBe(false);
              ids.add(result.id);
              
              // ID should be a valid UUID format
              expect(result.id).toMatch(
                /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
              );
            }
            
            // All IDs should be unique
            expect(ids.size).toBe(numUploads);
          }
        ),
        { numRuns: 5 }
      );
    });

    it('Property: Same file uploaded multiple times gets different IDs', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 100, max: 300 }),
          fc.integer({ min: 100, max: 300 }),
          async (width, height) => {
            const buffer = await createTestImage(width, height, 'png');
            const ids = new Set<string>();
            
            // Upload the same file 3 times
            for (let i = 0; i < 3; i++) {
              const file = createMockFile('same-file.png', buffer, 'image/png');
              const result = await assetProcessor.processImage(file, 'Same file');
              ids.add(result.id);
            }
            
            // All 3 uploads should have unique IDs
            expect(ids.size).toBe(3);
          }
        ),
        { numRuns: 5 }
      );
    });
  });

  /**
   * Property 22: Image Optimization Pipeline
   * 
   * Verify WebP conversion, responsive variants (320px, 768px, 1920px),
   * and aspect ratio preservation.
   * 
   * **Validates: Requirements 14.1, 14.2, 14.3, 14.4, 14.5**
   */
  describe('Property 22: Image Optimization Pipeline', () => {
    it('Property: All configured sizes generate variants', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 500, max: 2000 }),
          fc.integer({ min: 500, max: 2000 }),
          fc.constantFrom('jpeg', 'png', 'gif'),
          async (width, height, format) => {
            const buffer = await createTestImage(width, height, format);
            const mimetypeMap = {
              jpeg: 'image/jpeg',
              png: 'image/png',
              gif: 'image/gif',
            };
            const file = createMockFile(`test.${format}`, buffer, mimetypeMap[format]);

            const result = await assetProcessor.processImage(file, 'Test image');

            // Should have 3 variants (320, 768, 1920)
            expect(result.variants).toHaveLength(3);
            expect(result.variants.map(v => v.width)).toEqual([320, 768, 1920]);
            
            // All variants should exist as files
            for (const variant of result.variants) {
              const stats = await fs.stat(variant.path);
              expect(stats.isFile()).toBe(true);
              expect(variant.size).toBeGreaterThan(0);
            }
          }
        ),
        { numRuns: 5 }
      );
    });

    it('Property: Variants are converted to WebP format', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 500, max: 1500 }),
          fc.integer({ min: 500, max: 1500 }),
          async (width, height) => {
            const buffer = await createTestImage(width, height, 'jpeg');
            const file = createMockFile('test.jpg', buffer, 'image/jpeg');

            const result = await assetProcessor.processImage(file, 'Test image');

            // All variant paths should end with .webp
            for (const variant of result.variants) {
              expect(variant.path).toMatch(/\.webp$/);
              
              // Verify the file is actually WebP format
              const metadata = await sharp(variant.path).metadata();
              expect(metadata.format).toBe('webp');
            }
          }
        ),
        { numRuns: 5 }
      );
    });

    it('Property: Aspect ratio is preserved during resizing', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 800, max: 2000 }),
          fc.integer({ min: 600, max: 1500 }),
          async (width, height) => {
            const buffer = await createTestImage(width, height, 'png');
            const file = createMockFile('test.png', buffer, 'image/png');

            const result = await assetProcessor.processImage(file, 'Test image');

            const originalAspectRatio = width / height;

            // Check each variant preserves aspect ratio
            for (const variant of result.variants) {
              const metadata = await sharp(variant.path).metadata();
              const variantAspectRatio = metadata.width! / metadata.height!;
              
              // Allow small floating point differences (within 1%)
              const difference = Math.abs(variantAspectRatio - originalAspectRatio);
              const tolerance = originalAspectRatio * 0.01;
              expect(difference).toBeLessThanOrEqual(tolerance);
            }
          }
        ),
        { numRuns: 5 }
      );
    });

    it('Property: Images are not enlarged beyond original size', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 200, max: 500 }), // Small images
          fc.integer({ min: 200, max: 500 }),
          async (width, height) => {
            const buffer = await createTestImage(width, height, 'jpeg');
            const file = createMockFile('small.jpg', buffer, 'image/jpeg');

            const result = await assetProcessor.processImage(file, 'Small image');

            // Variants should not be larger than original
            for (const variant of result.variants) {
              const metadata = await sharp(variant.path).metadata();
              expect(metadata.width).toBeLessThanOrEqual(width);
              expect(metadata.height).toBeLessThanOrEqual(height);
            }
          }
        ),
        { numRuns: 5 }
      );
    });

    it('Property: Original file is retained', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 300, max: 800 }),
          fc.integer({ min: 300, max: 800 }),
          fc.constantFrom('jpeg', 'png', 'gif'),
          async (width, height, format) => {
            const buffer = await createTestImage(width, height, format);
            const mimetypeMap = {
              jpeg: 'image/jpeg',
              png: 'image/png',
              gif: 'image/gif',
            };
            const file = createMockFile(`test.${format}`, buffer, mimetypeMap[format]);

            const result = await assetProcessor.processImage(file, 'Test image');

            // Original file should exist
            const stats = await fs.stat(result.originalPath);
            expect(stats.isFile()).toBe(true);
            // Check that the path includes the uploads directory (handle both relative and absolute paths)
            expect(result.originalPath.includes('test-uploads-property')).toBe(true);
          }
        ),
        { numRuns: 5 }
      );
    });
  });

  /**
   * Property 23: Favicon Generation from Logo
   * 
   * Verify favicon.ico (16x16, 32x32) and apple-touch-icon.png (180x180) generation.
   * 
   * **Validates: Requirements 15.1, 15.2, 15.3, 15.4, 15.5**
   */
  describe('Property 23: Favicon Generation from Logo', () => {
    it('Property: Favicon files are generated from logo', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 200, max: 1000 }),
          fc.integer({ min: 200, max: 1000 }),
          async (width, height) => {
            // Create a logo file
            const buffer = await createTestImage(width, height, 'png');
            const logoPath = path.join(testUploadsDir, 'logo.png');
            await fs.writeFile(logoPath, buffer);

            // Generate favicon
            await assetProcessor.generateFavicon(logoPath);

            // Check that all favicon files exist
            const faviconPath = path.join(testPublicDir, 'favicon.ico');
            const appleTouchPath = path.join(testPublicDir, 'apple-touch-icon.png');
            const favicon16Path = path.join(testPublicDir, 'favicon-16x16.png');

            const faviconStats = await fs.stat(faviconPath);
            const appleTouchStats = await fs.stat(appleTouchPath);
            const favicon16Stats = await fs.stat(favicon16Path);

            expect(faviconStats.isFile()).toBe(true);
            expect(appleTouchStats.isFile()).toBe(true);
            expect(favicon16Stats.isFile()).toBe(true);
          }
        ),
        { numRuns: 5 }
      );
    });

    it('Property: Favicon has correct dimensions', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.integer({ min: 300, max: 800 }),
          fc.integer({ min: 300, max: 800 }),
          async (width, height) => {
            const buffer = await createTestImage(width, height, 'png');
            const logoPath = path.join(testUploadsDir, 'logo.png');
            await fs.writeFile(logoPath, buffer);

            await assetProcessor.generateFavicon(logoPath);

            // Check favicon.ico dimensions (32x32)
            const faviconPath = path.join(testPublicDir, 'favicon.ico');
            const faviconMetadata = await sharp(faviconPath).metadata();
            expect(faviconMetadata.width).toBe(32);
            expect(faviconMetadata.height).toBe(32);

            // Check apple-touch-icon.png dimensions (180x180)
            const appleTouchPath = path.join(testPublicDir, 'apple-touch-icon.png');
            const appleTouchMetadata = await sharp(appleTouchPath).metadata();
            expect(appleTouchMetadata.width).toBe(180);
            expect(appleTouchMetadata.height).toBe(180);

            // Check favicon-16x16.png dimensions (16x16)
            const favicon16Path = path.join(testPublicDir, 'favicon-16x16.png');
            const favicon16Metadata = await sharp(favicon16Path).metadata();
            expect(favicon16Metadata.width).toBe(16);
            expect(favicon16Metadata.height).toBe(16);
          }
        ),
        { numRuns: 5 }
      );
    });

    it('Property: Favicon generation fails for non-existent logo', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.string({ minLength: 5, maxLength: 20 }),
          async (filename) => {
            const nonExistentPath = path.join(testUploadsDir, `${filename}.png`);

            // Should throw an error
            await expect(assetProcessor.generateFavicon(nonExistentPath)).rejects.toThrow(
              /not found/i
            );
          }
        ),
        { numRuns: 5 }
      );
    });
  });

  /**
   * Property 24: Alt Text Requirement
   * 
   * Validate that alt text is required/stored.
   * 
   * **Validates: Requirements 16.2**
   */
  describe('Property 24: Alt Text Requirement', () => {
    it('Property: Alt text is accepted and stored', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.string({ minLength: 1, maxLength: 200 }),
          async (altText) => {
            const buffer = await createTestImage(300, 300, 'jpeg');
            const file = createMockFile('test.jpg', buffer, 'image/jpeg');

            const result = await assetProcessor.processImage(file, altText);

            expect(result.altText).toBe(altText);
          }
        ),
        { numRuns: 10 }
      );
    });

    it('Property: Empty alt text is stored as empty string', async () => {
      const buffer = await createTestImage(300, 300, 'png');
      const file = createMockFile('test.png', buffer, 'image/png');

      const result = await assetProcessor.processImage(file, '');

      expect(result.altText).toBe('');
    });

    it('Property: Alt text defaults to empty string when not provided', async () => {
      const buffer = await createTestImage(300, 300, 'gif');
      const file = createMockFile('test.gif', buffer, 'image/gif');

      const result = await assetProcessor.processImage(file);

      expect(result.altText).toBe('');
    });
  });

  /**
   * Property 25: Alt Text Storage
   * 
   * Verify alt text is properly stored in ProcessedAsset metadata.
   * 
   * **Validates: Requirements 16.3**
   */
  describe('Property 25: Alt Text Storage', () => {
    it('Property: Alt text is preserved in ProcessedAsset metadata', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.string({ minLength: 1, maxLength: 200 }),
          fc.integer({ min: 200, max: 800 }),
          fc.integer({ min: 200, max: 800 }),
          async (altText, width, height) => {
            const buffer = await createTestImage(width, height, 'jpeg');
            const file = createMockFile('test.jpg', buffer, 'image/jpeg');

            const result = await assetProcessor.processImage(file, altText);

            // Alt text should be in the returned ProcessedAsset
            expect(result.altText).toBe(altText);
            expect(typeof result.altText).toBe('string');
          }
        ),
        { numRuns: 10 }
      );
    });

    it('Property: ProcessedAsset contains all required metadata', async () => {
      await fc.assert(
        fc.asyncProperty(
          fc.string({ minLength: 1, maxLength: 100 }),
          fc.constantFrom('jpeg', 'png', 'gif'),
          async (altText, format) => {
            const buffer = await createTestImage(400, 400, format);
            const mimetypeMap = {
              jpeg: 'image/jpeg',
              png: 'image/png',
              gif: 'image/gif',
            };
            const file = createMockFile(`test.${format}`, buffer, mimetypeMap[format]);

            const result = await assetProcessor.processImage(file, altText);

            // Verify all required fields are present
            expect(result.id).toBeDefined();
            expect(typeof result.id).toBe('string');
            expect(result.originalPath).toBeDefined();
            expect(typeof result.originalPath).toBe('string');
            expect(result.originalFilename).toBe(`test.${format}`);
            expect(result.mimetype).toBe(mimetypeMap[format]);
            expect(result.size).toBeGreaterThan(0);
            expect(Array.isArray(result.variants)).toBe(true);
            expect(result.altText).toBe(altText);
            expect(result.uploadedAt).toBeDefined();
            expect(new Date(result.uploadedAt).toISOString()).toBe(result.uploadedAt);
          }
        ),
        { numRuns: 10 }
      );
    });
  });
});
