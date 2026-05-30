<template>
  <div>
    <h1>Categories</h1>

    <div class="panel">
      <h2>Create category</h2>
      <form @submit.prevent="create">
        <div class="fields">
          <div class="field">
            <label>Name</label>
            <input v-model="form.name" placeholder="e.g. Ocean Cleanup" required />
          </div>
          <div class="field">
            <label>Slug</label>
            <input v-model="form.slug" placeholder="e.g. ocean_cleanup" required />
          </div>
          <div class="field full">
            <label>Description</label>
            <input v-model="form.description" placeholder="Short description (optional)" />
          </div>
        </div>
        <p v-if="createError" class="error">{{ createError }}</p>
        <button type="submit" :disabled="creating">
          {{ creating ? 'Creating...' : 'Create category' }}
        </button>
      </form>
    </div>

    <div class="page-header">
      <h2>Existing categories</h2>
    </div>

    <div v-if="loading" class="state">Loading...</div>
    <div v-else-if="listError" class="state error">{{ listError }}</div>

    <table v-else>
      <thead>
        <tr>
          <th>Name</th>
          <th>Slug</th>
          <th>Description</th>
          <th>Created</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="cat in categories" :key="cat.id">
          <td class="bold">{{ cat.name }}</td>
          <td class="mono">{{ cat.slug }}</td>
          <td>{{ cat.description ?? '—' }}</td>
          <td>{{ formatDate(cat.createdAt) }}</td>
        </tr>
        <tr v-if="categories.length === 0">
          <td colspan="4" class="empty">No categories yet</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { getCategories, createCategory } from '../lib/api';

type Category = { id: string; name: string; slug: string; description: string | null; createdAt: string };

const categories = ref<Category[]>([]);
const loading = ref(true);
const listError = ref('');
const creating = ref(false);
const createError = ref('');

const form = ref({ name: '', slug: '', description: '' });

onMounted(fetchCategories);

async function fetchCategories() {
  try {
    categories.value = await getCategories();
  } catch (e: any) {
    listError.value = e.message;
  } finally {
    loading.value = false;
  }
}

async function create() {
  creating.value = true;
  createError.value = '';
  try {
    await createCategory(form.value);
    form.value = { name: '', slug: '', description: '' };
    await fetchCategories();
  } catch (e: any) {
    createError.value = e.message;
  } finally {
    creating.value = false;
  }
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString();
}
</script>

<style scoped>
h1 { font-size: 24px; font-weight: 700; margin-bottom: 24px; }
h2 { font-size: 16px; font-weight: 700; margin-bottom: 16px; }
.page-header { margin: 28px 0 16px; }

.panel {
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  margin-bottom: 28px;
}

.fields { display: flex; flex-wrap: wrap; gap: 14px; margin-bottom: 16px; }
.field { display: flex; flex-direction: column; gap: 6px; flex: 1; min-width: 180px; }
.field.full { flex-basis: 100%; }

label { font-size: 12px; font-weight: 600; color: #555; text-transform: uppercase; letter-spacing: 0.5px; }

input {
  padding: 10px 12px;
  border: 1.5px solid #e5e5e5;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
}
input:focus { border-color: #22c55e; }

button {
  padding: 10px 20px;
  background: #22c55e;
  color: #fff;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
}
button:disabled { opacity: 0.6; cursor: not-allowed; }

.error { color: #dc2626; font-size: 13px; margin-bottom: 12px; }

table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
th { text-align: left; padding: 12px 16px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #888; background: #fafafa; border-bottom: 1px solid #eee; }
td { padding: 12px 16px; border-bottom: 1px solid #f0f0f0; font-size: 14px; }
tr:last-child td { border-bottom: none; }
.bold { font-weight: 600; }
.mono { font-family: monospace; font-size: 12px; color: #555; }
.empty { text-align: center; color: #aaa; padding: 32px; }
.state { padding: 48px; text-align: center; color: #888; }
</style>
