import { Request, Response, NextFunction } from 'express';

/**
 * Middleware untuk membatasi akses endpoint audit dan verifikasi blockchain
 * Hanya pengguna dengan role 'admin' yang diizinkan mengakses.
 */
export function verifyAdmin(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const userRole = (req.headers['x-user-role'] as string | undefined)?.toLowerCase();
  const authHeader = req.headers['authorization'];

  // Cek apakah header peran pengguna adalah admin
  if (userRole === 'admin') {
    return next();
  }

  // Jika menyertakan token bearer dan terdeteksi admin secret / payload
  if (authHeader && authHeader.toLowerCase().includes('admin')) {
    return next();
  }

  res.status(403).json({
    success: false,
    error: 'Akses ditolak. Seluruh fitur pencatatan dan verifikasi blockchain hanya dapat diakses oleh Admin Bun Atelier.',
  });
}

