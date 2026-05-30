<template>
  <div>
    <div class="page-header">
      <h1>Acts</h1>
      <span class="count">{{ acts.length }} total</span>
    </div>

    <div v-if="loading" class="state">Loading...</div>
    <div v-else-if="error" class="state error">{{ error }}</div>

    <table v-else>
      <thead>
        <tr>
          <th>Photo</th>
          <th>Category</th>
          <th>Location</th>
          <th>Date</th>
          <th>User</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="act in acts" :key="act.id">
          <td>
            <img :src="act.photoUrl" :alt="act.category" class="thumb" />
          </td>
          <td>
            <span :class="['badge', act.category]">{{ LABELS[act.category] ?? act.category }}</span>
          </td>
          <td class="mono">{{ act.lat.toFixed(5) }}, {{ act.long.toFixed(5) }}</td>
          <td>{{ formatDate(act.createdAt) }}</td>
          <td class="mono">{{ act.userId.slice(0, 8) }}…</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { getActs } from '../lib/api';

type Act = {
  id: string;
  userId: string;
  category: string;
  photoUrl: string;
  lat: number;
  long: number;
  createdAt: string;
};

const LABELS: Record<string, string> = {
  tree_mangrove: 'Tree / Mangrove',
  wildlife: 'Wildlife',
  recycling: 'Recycling',
  litter_cleanup: 'Litter Cleanup',
};

const acts = ref<Act[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);

onMounted(async () => {
  try {
    acts.value = await getActs();
  } catch (err: any) {
    error.value = err.message;
  } finally {
    loading.value = false;
  }
});

function formatDate(iso: string) {
  return new Date(iso).toLocaleString();
}
</script>

<style scoped>
.page-header { display: flex; align-items: baseline; gap: 12px; margin-bottom: 24px; }
h1 { font-size: 24px; font-weight: 700; }
.count { color: #888; font-size: 14px; }

table {
  width: 100%;
  border-collapse: collapse;
  background: #fff;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
th {
  text-align: left;
  padding: 12px 16px;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: #888;
  background: #fafafa;
  border-bottom: 1px solid #eee;
}
td { padding: 12px 16px; border-bottom: 1px solid #f0f0f0; font-size: 14px; vertical-align: middle; }
tr:last-child td { border-bottom: none; }

.thumb { width: 56px; height: 56px; object-fit: cover; border-radius: 6px; }
.mono { font-family: monospace; font-size: 12px; color: #555; }
.state { padding: 48px; text-align: center; color: #888; }
.error { color: #dc2626; }

.badge { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 600; }
.badge.tree_mangrove { background: #dcfce7; color: #16a34a; }
.badge.wildlife { background: #fef3c7; color: #d97706; }
.badge.recycling { background: #dbeafe; color: #2563eb; }
.badge.litter_cleanup { background: #fee2e2; color: #dc2626; }
</style>
