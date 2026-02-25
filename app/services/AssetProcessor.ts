/**
 * AssetProcessor Service
 * 
 * Handles image upload, validation, optimization, and processing.
 * Generates responsive image variants and favicon files.
 */

import sharp from 'sharp';
import { v4 as uuidv4 } from 'uuid';
import * as fs from 'fs/promises';
import * as path from 'path';
import { ProcessedAsset, ImageVariant, UploadedFile } from '../types/asset.js';
import { Logger } from './Logger.js';

export interface AssetProcessorConfig {
  uploadsDir: string;
  processedDir: string;
  publicDir: string;
  maxFileSize: number; // Bytes
  sizes: number[]; // Responsive image widths
  webpQuality: number;
}

export class AssetProcessor {
  private config: AssetProcessorConfig;
  private logger: Logger;
  private readonly VALID_FORMATS = ['image/jpeg', 'image/png', 'image/gif'];

  constructor(config: AssetProcessorConfig, logger: Logger) {
    this.config = config;
    this.logger = logger;
  }

  /**
   * Process uploaded image: validate, save original, generate variants
   */
  async processImage(file: UploadedFile, altText: string = ''): Promise<ProcessedAsset> {
    // Validate file
    this.validateImage(file);

    // Generate unique ID
    const id = uuidv4();
    const ext = path.extname(file.name);
    const originalFilename = file.name;

    // Save original
    const originalPath = path.join(this.config.uploadsDir, `${id}${ext}`);
    await fs.mkdir(this.config.uploadsDir, { recursive: true });
    await fs.writeFile(originalPath, file.data);

    this.logger.info('Image uploaded', {
      id,
      originalFilename,
      size: file.size,
      mimetype: file.mimetype,
    });

    // Generate responsive variants
    const variants: ImageVariant[] = [];
    for (const width of this.config.sizes) {
      const variant = await this.generateVariant(originalPath, id, width);
      variants.push(variant);
    }

    return {
      id,
      originalPath,
      originalFilename,
      mimetype: file.mimetype,
      size: file.size,
      variants,
      altText,
      uploadedAt: new Date().toISOString(),
    };
  }

  /**
   * Generate favicon from logo
   */
  async generateFavicon(logoPath: string): Promise<void> {
    this.logger.info('Generating favicon from logo', { logoPath });

    // Ensure logo exists
    try {
      await fs.access(logoPath);
    } catch (error) {
      throw new AssetProcessorError(`Logo file not found: ${logoPath}`);
    }

    // Generate favicon.ico (32x32)
    const faviconPath = path.join(this.config.publicDir, 'favicon.ico');
    await sharp(logoPath)
      .resize(32, 32, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
      .png()
      .toFile(faviconPath);

    // Generate apple-touch-icon.png (180x180)
    const appleTouchPath = path.join(this.config.publicDir, 'apple-touch-icon.png');
    await sharp(logoPath)
      .resize(180, 180, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
      .png()
      .toFile(appleTouchPath);

    // Generate additional favicon sizes
    const favicon16Path = path.join(this.config.publicDir, 'favicon-16x16.png');
    await sharp(logoPath)
      .resize(16, 16, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
      .png()
      .toFile(favicon16Path);

    this.logger.info('Favicon generated successfully', {
      faviconPath,
      appleTouchPath,
      favicon16Path,
    });
  }

  /**
   * Validate uploaded image
   */
  private validateImage(file: UploadedFile): void {
    // Check file size
    if (file.size > this.config.maxFileSize) {
      throw new AssetProcessorError(
        `File exceeds ${this.config.maxFileSize / (1024 * 1024)}MB limit`
      );
    }

    // Check file format
    if (!this.VALID_FORMATS.includes(file.mimetype)) {
      throw new AssetProcessorError(
        `Invalid image format. Accepted formats: JPEG, PNG, GIF`
      );
    }
  }

  /**
   * Generate a responsive image variant
   */
  private async generateVariant(
    originalPath: string,
    id: string,
    width: number
  ): Promise<ImageVariant> {
    const outputDir = path.join(this.config.processedDir, width.toString());
    await fs.mkdir(outputDir, { recursive: true });

    const outputPath = path.join(outputDir, `${id}.webp`);

    // Generate WebP variant
    await sharp(originalPath)
      .resize(width, null, {
        withoutEnlargement: true,
        fit: 'inside',
      })
      .webp({ quality: this.config.webpQuality })
      .toFile(outputPath);

    // Get file size
    const stats = await fs.stat(outputPath);

    this.logger.debug('Image variant generated', {
      id,
      width,
      size: stats.size,
      outputPath,
    });

    return {
      width,
      path: outputPath,
      size: stats.size,
    };
  }

  /**
   * Check if image format is valid
   */
  isValidImageFormat(mimetype: string): boolean {
    return this.VALID_FORMATS.includes(mimetype);
  }

  /**
   * Delete asset and all its variants
   */
  async deleteAsset(asset: ProcessedAsset): Promise<void> {
    this.logger.info('Deleting asset', { id: asset.id });

    // Delete original
    try {
      await fs.unlink(asset.originalPath);
    } catch (error) {
      this.logger.warn('Failed to delete original file', {
        path: asset.originalPath,
        error,
      });
    }

    // Delete variants
    for (const variant of asset.variants) {
      try {
        await fs.unlink(variant.path);
      } catch (error) {
        this.logger.warn('Failed to delete variant', {
          path: variant.path,
          error,
        });
      }
    }
  }
}

/**
 * Custom error class for AssetProcessor errors
 */
export class AssetProcessorError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AssetProcessorError';
  }
}
