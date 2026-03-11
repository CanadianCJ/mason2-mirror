export default {
  expo: {
    name: "Onyx",
    slug: "onyx",
    scheme: "onyx",
    ios: { bundleIdentifier: "com.yourcompany.onyx" },
    android: { package: "com.yourcompany.onyx" },
    plugins: ["expo-router"],
    icon: "./assets/icon.png",
    splash: { image: "./assets/splash.png", resizeMode: "contain", backgroundColor: "#0A0A0C" },
    extra: {
      API_BASE: process.env.API_BASE ?? "http://localhost:8000"
    }
  }
}
