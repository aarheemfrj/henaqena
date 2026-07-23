import { NextResponse } from 'next/server';
import * as XLSX from 'xlsx';

const headers = [
  'external_id', 'name', 'category', 'subcategory', 'description', 'city', 'area', 'village', 'address',
  'phone', 'whatsapp', 'email', 'website', 'facebook', 'instagram', 'tiktok',
  'latitude', 'longitude', 'opening_time', 'closing_time', 'opening_hours',
  'service_mode', 'phone_type', 'is_verified',
  'image_1', 'image_2', 'image_3', 'image_4', 'image_5', 'image_6', 'image_7', 'image_8', 'image_9', 'image_10',
];

export async function GET() {
  const workbook = XLSX.utils.book_new();
  const worksheet = XLSX.utils.aoa_to_sheet([
    headers,
    ['example-001', 'مثال نشاط', 'مطاعم', '', 'وصف اختياري', 'قنا', 'وسط البلد', '', 'العنوان بالتفصيل', '01000000000', '', '', '', '', '', '', '26.164', '32.726', '09:00', '23:00', '', 'LOCAL', 'BUSINESS', 'true', '', '', '', '', '', '', '', '', '', ''],
  ]);
  XLSX.utils.book_append_sheet(workbook, worksheet, 'providers');
  const buffer = XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
  return new NextResponse(buffer, {
    headers: {
      'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Content-Disposition': 'attachment; filename="henaqena-import-template.xlsx"',
      'Cache-Control': 'no-store',
    },
  });
}
