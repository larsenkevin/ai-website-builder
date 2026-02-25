/**
 * Assets Routes
 * 
 * Handles image upload, processing, and management.
 */

import { Router, Request, Response } from 'express';
import { AssetProcessor } from '../services/AssetProcessor.js';
import { Logger } from '../services/Logger.js';
import { UploadedFile } from '../types/asset.js';

export function createAssetsRouter(
  assetProcessor: AssetProcessor,
  logger: Logger
): Router {
  const router = Router();

  /**
   * POST /api/assets/upload
   * Upload and process an image
   */
  router.post('/upload', async (req: Request, res: Response): Promise<void> => {
    try {
      if (!req.files || !req.files.image) {
        res.status(400).json({
          error: 'No image file provided',
        });
        return;
      }

      const { altText } = req.body;

      if (!altText) {
        res.status(400).json({
          error: 'Alt text is required',
        });
        return;
      }

      const file = req.files.image as any;
      logger.info('Processing image upload', {
        filename: file.name,
        size: file.size,
        mimetype: file.mimetype,
      });

      // Convert to UploadedFile format
      const uploadedFile: UploadedFile = {
        name: file.name,
        data: file.data,
        size: file.size,
        mimetype: file.mimetype,
        mv: async (path: string) => {
          return file.mv(path);
        },
      };

      const asset = await assetProcessor.processImage(uploadedFile, altText);

      res.json({
        success: true,
        asset,
      });
    } catch (error: any) {
      logger.error('Image upload failed', {
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'Image upload failed',
        message: error.message,
      });
    }
  });

  /**
   * POST /api/assets/favicon
   * Generate favicon from logo
   */
  router.post('/favicon', async (req: Request, res: Response): Promise<void> => {
    try {
      const { logoPath } = req.body;

      if (!logoPath) {
        res.status(400).json({
          error: 'Logo path is required',
        });
        return;
      }

      logger.info('Generating favicon', { logoPath });

      await assetProcessor.generateFavicon(logoPath);

      res.json({
        success: true,
        message: 'Favicon generated successfully',
      });
    } catch (error: any) {
      logger.error('Favicon generation failed', {
        error: error.message,
        stack: error.stack,
      });

      res.status(500).json({
        error: 'Favicon generation failed',
        message: error.message,
      });
    }
  });

  return router;
}
