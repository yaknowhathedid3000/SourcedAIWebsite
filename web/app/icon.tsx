import { ImageResponse } from "next/og";

export const size = { width: 512, height: 512 };
export const contentType = "image/png";

export default function Icon() {
  return new ImageResponse(
    (
      <div style={{ width: "100%", height: "100%", display: "flex", alignItems: "center", justifyContent: "center", background: "#ffffff", borderRadius: 112 }}>
        <svg viewBox="0 0 100 100" width="360" height="360">
          <path d="M20 4 h60 a16 16 0 0 1 16 16 v58 c0 9 -8 14 -15 9 c-4 -3 -8 -3 -12 0 c-4 3 -8 3 -12 0 c-4 -3 -8 -3 -12 0 c-4 3 -8 3 -12 0 c-4 -3 -8 -3 -12 0 c-7 5 -17 0 -17 -9 v-58 a16 16 0 0 1 16 -16 z" fill="#1C1C1E" />
          <rect x="34" y="36" width="8" height="24" rx="4" fill="#fff" />
          <rect x="58" y="36" width="8" height="24" rx="4" fill="#fff" />
        </svg>
      </div>
    ),
    size,
  );
}
