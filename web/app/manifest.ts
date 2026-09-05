import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Albo",
    short_name: "Albo",
    description: "Save anything, find it later, and get plans out of the group chat.",
    start_url: "/library",
    display: "standalone",
    background_color: "#ffffff",
    theme_color: "#ffffff",
    icons: [{ src: "/icon", sizes: "512x512", type: "image/png" }],
  };
}
