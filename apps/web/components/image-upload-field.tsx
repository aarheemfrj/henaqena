/* eslint-disable @next/next/no-img-element -- freshly uploaded previews come from our own uploads host, not next/image's optimizer */
'use client';

import { useState } from 'react';

export type UploadedImage = { url: string; kind?: string };

const fileToBase64 = (file: File) => new Promise<string>((resolve, reject) => {
  const reader = new FileReader();
  reader.onload = () => resolve(String(reader.result).split(',')[1] ?? '');
  reader.onerror = () => reject(reader.error);
  reader.readAsDataURL(file);
});

export function ImageUploadField({ name, uploadUrl, max = 10, label = 'الصور', initialImages = [] }: { name: string; uploadUrl: string; max?: number; label?: string; initialImages?: UploadedImage[] }) {
  const [images, setImages] = useState<UploadedImage[]>(initialImages.slice(0, max));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onFiles = async (fileList: FileList | null) => {
    if (!fileList || fileList.length === 0) return;
    setError(null);
    setBusy(true);
    try {
      const files = Array.from(fileList).slice(0, Math.max(0, max - images.length));
      const payload = await Promise.all(files.map(async (file) => ({ base64: await fileToBase64(file), mimeType: file.type })));
      const response = await fetch(uploadUrl, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ images: payload }) });
      if (!response.ok) { const body = await response.json().catch(() => null); throw new Error(body?.message ?? 'تعذر رفع الصور'); }
      const body = await response.json() as { images: UploadedImage[] };
      setImages((current) => [...current, ...body.images].slice(0, max));
    } catch (uploadError) {
      setError(uploadError instanceof Error ? uploadError.message : 'تعذر رفع الصور');
    } finally {
      setBusy(false);
    }
  };

  return <div className="imageUpload">
    <span className="fieldLabel">{label}</span>
    <label className="uploadDropzone">
      <input type="file" accept="image/jpeg,image/png,image/webp" multiple disabled={busy || images.length >= max} onChange={(event) => { void onFiles(event.target.files); event.target.value = ''; }} />
      <span>{busy ? 'جارٍ الرفع…' : 'اختر صورًا من جهازك (كاميرا أو معرض الصور)'}</span>
    </label>
    {error && <p className="formError">{error}</p>}
    {images.length > 0 && <div className="uploadThumbs">
      {images.map((image, index) => <div className="uploadThumb" key={image.url}>
        <img src={image.url} alt="" />
        <button type="button" onClick={() => setImages((current) => current.filter((_, position) => position !== index))}>×</button>
      </div>)}
    </div>}
    <input type="hidden" name={name} value={JSON.stringify(images)} />
  </div>;
}
