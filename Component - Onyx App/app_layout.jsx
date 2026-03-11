import { Stack } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";

export default function RootLayout() {
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: "#111" }}>
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: "#111" },
          headerTintColor: "#fff",
          contentStyle: { backgroundColor: "#111" },
        }}
      >
        <Stack.Screen name="index" options={{ title: "Onyx" }} />
        <Stack.Screen name="updates" options={{ title: "What's New" }} />
        <Stack.Screen name="clients" options={{ title: "Clients" }} />
        <Stack.Screen name="projects" options={{ title: "Projects" }} />
        <Stack.Screen name="settings" options={{ title: "Settings" }} />
      </Stack>
    </SafeAreaView>
  );
}
