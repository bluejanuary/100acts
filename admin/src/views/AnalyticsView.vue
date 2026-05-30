<template>
  <div>
    <h1>Analytics</h1>

    <div v-if="loading" class="state">Loading...</div>
    <div v-else-if="error" class="state error">{{ error }}</div>

    <template v-else>
      <!-- Platform stats -->
      <h2>Platform</h2>
      <div class="stats">
        <div class="stat-card green">
          <span class="stat-value">{{ data.totalActs }}</span>
          <span class="stat-label">Total Acts</span>
        </div>
        <div class="stat-card blue">
          <span class="stat-value">{{ data.totalUsers }}</span>
          <span class="stat-label">Total Users</span>
        </div>
        <div class="stat-card teal">
          <span class="stat-value">{{ data.actsToday }}</span>
          <span class="stat-label">Acts Today</span>
        </div>
        <div class="stat-card purple">
          <span class="stat-value">{{ data.actsThisWeek }}</span>
          <span class="stat-label">This Week</span>
        </div>
        <div class="stat-card orange">
          <span class="stat-value">{{ data.actsThisMonth }}</span>
          <span class="stat-label">This Month</span>
        </div>
      </div>

      <!-- By category -->
      <h2>Acts by category</h2>
      <div class="categories">
        <div v-for="item in data.byCategory" :key="item.category" class="cat-row">
          <div class="cat-info">
            <span :class="['badge', item.category]">{{ LABELS[item.category] ?? item.category }}</span>
            <span class="cat-count">{{ item.count }} acts</span>
          </div>
          <div class="bar-wrap">
            <div
              class="bar"
              :style="{ width: barWidth(item.count) + '%', background: BAR_COLORS[item.category] ?? '#22c55e' }"
            />
          </div>
        </div>
        <p v-if="data.byCategory.length === 0" class="empty">No acts recorded yet</p>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { getAnalytics } from '../lib/api';

const LABELS: Record<string, string> = {
  tree_mangrove: 'Tree / Mangrove',
  wildlife: 'Wildlife',
  recycling: 'Recycling',
  litter_cleanup: 'Litter Cleanup',
};

const BAR_COLORS: Record<string, string> = {
  tree_mangrove: '#16a34a',
  wildlife: '#d97706',
  recycling: '#2563eb',
  litter_cleanup: '#dc2626',
};

type Analytics = {
  totalActs: number;
  totalUsers: number;
  actsToday: number;
  actsThisWeek: number;
  actsThisMonth: number;
  byCategory: { category: string; count: number }[];
};

const data = ref<Analytics>({
  totalActs: 0, totalUsers: 0, actsToday: 0,
  actsThisWeek: 0, actsThisMonth: 0, byCategory: [],
});
const loading = ref(true);
const error = ref('');

onMounted(async () => {
  try {
    data.value = await getAnalytics();
  } catch (e: any) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
});

const maxCount = computed(() => Math.max(...data.value.byCategory.map((c) => c.count), 1));
function barWidth(count: number) {
  return Math.round((count / maxCount.value) * 100);
}
</script>

<style scoped>
h1 { font-size: 24px; font-weight: 700; margin-bottom: 24px; }
h2 { font-size: 14px; font-weight: 600; color: #888; text-transform: uppercase; letter-spacing: 0.5px; margin: 28px 0 14px; }

.state { padding: 48px; text-align: center; color: #888; }
.error { color: #dc2626; }

.stats { display: flex; flex-wrap: wrap; gap: 14px; }
.stat-card { background: #fff; border-radius: 12px; padding: 24px 28px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); display: flex; flex-direction: column; gap: 6px; min-width: 140px; border-top: 3px solid transparent; }
.stat-card.green { border-color: #22c55e; }
.stat-card.blue { border-color: #3b82f6; }
.stat-card.teal { border-color: #14b8a6; }
.stat-card.purple { border-color: #8b5cf6; }
.stat-card.orange { border-color: #f97316; }
.stat-value { font-size: 36px; font-weight: 800; color: #1a1a1a; }
.stat-label { font-size: 12px; color: #888; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }

.categories { background: #fff; border-radius: 12px; padding: 20px 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); display: flex; flex-direction: column; gap: 16px; }
.cat-row { display: flex; flex-direction: column; gap: 8px; }
.cat-info { display: flex; align-items: center; justify-content: space-between; }
.cat-count { font-size: 13px; font-weight: 600; color: #555; }
.bar-wrap { height: 8px; background: #f0f0f0; border-radius: 99px; overflow: hidden; }
.bar { height: 100%; border-radius: 99px; transition: width 0.4s ease; }

.badge { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 600; }
.badge.tree_mangrove { background: #dcfce7; color: #16a34a; }
.badge.wildlife { background: #fef3c7; color: #d97706; }
.badge.recycling { background: #dbeafe; color: #2563eb; }
.badge.litter_cleanup { background: #fee2e2; color: #dc2626; }

.empty { color: #aaa; text-align: center; padding: 16px; }
</style>
