<template>
  <div class="card">
    <h1>100acts Admin</h1>
    <p class="sub">Sign in to continue</p>

    <form @submit.prevent="submit">
      <input v-model="email" type="email" placeholder="Email" required />
      <input v-model="password" type="password" placeholder="Password" required />
      <p v-if="error" class="error">{{ error }}</p>
      <button type="submit" :disabled="loading">
        {{ loading ? 'Signing in...' : 'Sign in' }}
      </button>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { login } from '../lib/api';

const router = useRouter();
const email = ref('');
const password = ref('');
const loading = ref(false);
const error = ref('');

async function submit() {
  loading.value = true;
  error.value = '';
  try {
    await login(email.value, password.value);
    router.push('/analytics');
  } catch (e: any) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.card {
  background: #fff;
  padding: 40px;
  border-radius: 16px;
  box-shadow: 0 4px 24px rgba(0,0,0,0.08);
  width: 100%;
  max-width: 380px;
}

h1 { font-size: 24px; font-weight: 800; color: #22c55e; margin-bottom: 4px; }
.sub { color: #888; font-size: 14px; margin-bottom: 28px; }

form { display: flex; flex-direction: column; gap: 14px; }

input {
  padding: 12px 14px;
  border: 1.5px solid #e5e5e5;
  border-radius: 8px;
  font-size: 15px;
  outline: none;
  transition: border-color 0.15s;
}
input:focus { border-color: #22c55e; }

button {
  padding: 13px;
  background: #22c55e;
  color: #fff;
  border: none;
  border-radius: 8px;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
}
button:disabled { opacity: 0.6; cursor: not-allowed; }

.error { color: #dc2626; font-size: 13px; }
</style>
