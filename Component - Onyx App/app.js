import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View, Image } from 'react-native';
import axios from 'axios';
import { useEffect, useState } from 'react';

export default function App() {
  const [status, setStatus] = useState("Checking backend...");

  useEffect(() => {
    const check = async () => {
      try {
        const res = await axios.get(`${process.env.EXPO_PUBLIC_API_BASE || "http://127.0.0.1:8000"}/health`);
        if (res.data.ok) {
          setStatus("✅ Onyx backend is online");
        } else {
          setStatus("⚠️ Backend reachable but not OK");
        }
      } catch (err) {
        setStatus("❌ Could not reach backend");
      }
    };
    check();
  }, []);

  return (
    <View style={styles.container}>
      <Image source={require('./assets/icon.png')} style={styles.icon} />
      <Text style={styles.title}>ONYX</Text>
      <Text style={styles.subtitle}>Business Manager</Text>
      <Text style={styles.status}>{status}</Text>
      <StatusBar style="light" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#111',
    alignItems: 'center',
    justifyContent: 'center',
  },
  icon: {
    width: 120,
    height: 120,
    marginBottom: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#fff',
  },
  subtitle: {
    fontSize: 16,
    color: '#aaa',
    marginBottom: 20,
  },
  status: {
    fontSize: 14,
    color: '#0f0',
    marginTop: 20,
  },
});
