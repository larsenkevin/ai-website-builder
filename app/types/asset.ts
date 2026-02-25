/**
 * Asset type definitions
 */

export interface ImageVariant {
  width: number;
  path: string;
  size: number; // Bytes
}

export interface ProcessedAsset {
  id: string; // Unique identifier
  originalPath: string; // Path to original upload
  originalFilename: string;
  mimetype: string;
  size: number; // Bytes
  variants: ImageVariant[];
  altText: string;
  uploadedAt: string; // ISO 8601 timestamp
}

export interface UploadedFile {
  name: string;
  data: Buffer;
  size: number;
  mimetype: string;
  mv: (path: string) => Promise<void>;
}
