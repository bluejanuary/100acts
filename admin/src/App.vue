<template>
  <div v-if="isPublic" class="public-page">
    <router-view />
  </div>

  <div v-else id="shell">
    <aside class="sidebar">
      <div class="brand">100acts</div>
      <nav>
        <router-link to="/analytics">
          <span class="icon">📊</span> Analytics
        </router-link>
        <router-link to="/users">
          <span class="icon">👥</span> Users
        </router-link>
        <router-link to="/acts">
          <span class="icon">🌿</span> Acts
        </router-link>
        <router-link to="/categories">
          <span class="icon">🏷️</span> Categories
        </router-link>
      </nav>
      <button class="logout" @click="logout">Log out</button>
    </aside>

    <main>
      <router-view />
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';

const route = useRoute();
const router = useRouter();

const isPublic = computed(() => route.meta.public);

function logout() {
  localStorage.removeItem('auth_token');
  router.push('/login');
}
</script>

<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: system-ui, sans-serif; background: #f5f5f5; color: #1a1a1a; }

.public-page { min-height: 100vh; display: flex; align-items: center; justify-content: center; background: #f5f5f5; }

#shell { display: flex; min-height: 100vh; }

.sidebar {
  width: 220px;
  background: #fff;
  border-right: 1px solid #e5e5e5;
  display: flex;
  flex-direction: column;
  padding: 24px 16px;
  gap: 4px;
  position: fixed;
  top: 0; left: 0; bottom: 0;
}

.brand {
  font-size: 20px;
  font-weight: 800;
  color: #22c55e;
  padding: 0 8px 24px;
}

nav { display: flex; flex-direction: column; gap: 4px; flex: 1; }

nav a {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 8px;
  text-decoration: none;
  color: #555;
  font-size: 14px;
  font-weight: 500;
  transition: background 0.15s;
}

nav a:hover { background: #f5f5f5; }
nav a.router-link-active { background: #f0fdf4; color: #16a34a; font-weight: 600; }

.icon { font-size: 16px; }

.logout {
  background: none;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  padding: 10px 12px;
  cursor: pointer;
  color: #dc2626;
  font-size: 14px;
  font-weight: 500;
  text-align: left;
}
.logout:hover { background: #fee2e2; }

main { margin-left: 220px; flex: 1; padding: 32px; }
</style>
