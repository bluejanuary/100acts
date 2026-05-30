<template>
  <div>
    <h1>Users</h1>

    <!-- Create user -->
    <div class="panel">
      <h2>Add user</h2>
      <form @submit.prevent="create">
        <div class="fields">
          <div class="field">
            <label>Email</label>
            <input v-model="form.email" type="email" placeholder="user@example.com" required />
          </div>
          <div class="field">
            <label>Password</label>
            <input v-model="form.password" type="password" placeholder="Min 8 characters" required minlength="8" />
          </div>
        </div>
        <p v-if="createError" class="error">{{ createError }}</p>
        <button type="submit" :disabled="creating">
          {{ creating ? 'Creating...' : 'Create user' }}
        </button>
      </form>
    </div>

    <!-- Users table -->
    <div class="page-header">
      <h2>All users</h2>
      <span class="count">{{ users.length }} total</span>
    </div>

    <div v-if="loading" class="state">Loading...</div>
    <div v-else-if="listError" class="state error">{{ listError }}</div>

    <table v-else>
      <thead>
        <tr>
          <th>Email</th>
          <th>Joined</th>
          <th>Last sign in</th>
          <th>ID</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="user in users" :key="user.id">
          <td class="email">{{ user.email }}</td>
          <td>{{ formatDate(user.createdAt) }}</td>
          <td>{{ user.lastSignIn ? formatDate(user.lastSignIn) : '—' }}</td>
          <td class="mono">{{ user.id.slice(0, 8) }}…</td>
          <td>
            <button class="delete" @click="remove(user.id, user.email)">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { getUsers, createUser, deleteUser } from '../lib/api';

type User = { id: string; email: string; createdAt: string; lastSignIn: string | null };

const users = ref<User[]>([]);
const loading = ref(true);
const listError = ref('');
const creating = ref(false);
const createError = ref('');
const form = ref({ email: '', password: '' });

onMounted(fetchUsers);

async function fetchUsers() {
  try {
    users.value = await getUsers();
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
    await createUser(form.value);
    form.value = { email: '', password: '' };
    await fetchUsers();
  } catch (e: any) {
    createError.value = e.message;
  } finally {
    creating.value = false;
  }
}

async function remove(id: string, email: string) {
  if (!confirm(`Delete user ${email}? This cannot be undone.`)) return;
  try {
    await deleteUser(id);
    users.value = users.value.filter((u) => u.id !== id);
  } catch (e: any) {
    alert(e.message);
  }
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString();
}
</script>

<style scoped>
h1 { font-size: 24px; font-weight: 700; margin-bottom: 24px; }
h2 { font-size: 16px; font-weight: 700; margin-bottom: 16px; }
.page-header { display: flex; align-items: baseline; gap: 12px; margin: 28px 0 16px; }
.count { color: #888; font-size: 14px; }

.panel { background: #fff; border-radius: 12px; padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); margin-bottom: 28px; }
.fields { display: flex; gap: 14px; margin-bottom: 16px; flex-wrap: wrap; }
.field { display: flex; flex-direction: column; gap: 6px; flex: 1; min-width: 200px; }
label { font-size: 12px; font-weight: 600; color: #555; text-transform: uppercase; letter-spacing: 0.5px; }
input { padding: 10px 12px; border: 1.5px solid #e5e5e5; border-radius: 8px; font-size: 14px; outline: none; }
input:focus { border-color: #22c55e; }
button { padding: 10px 20px; background: #22c55e; color: #fff; border: none; border-radius: 8px; font-size: 14px; font-weight: 700; cursor: pointer; }
button:disabled { opacity: 0.6; cursor: not-allowed; }

.error { color: #dc2626; font-size: 13px; margin-bottom: 12px; }

table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
th { text-align: left; padding: 12px 16px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #888; background: #fafafa; border-bottom: 1px solid #eee; }
td { padding: 12px 16px; border-bottom: 1px solid #f0f0f0; font-size: 14px; vertical-align: middle; }
tr:last-child td { border-bottom: none; }
.email { font-weight: 500; }
.mono { font-family: monospace; font-size: 12px; color: #999; }
.delete { padding: 5px 12px; background: #fff; color: #dc2626; border: 1px solid #dc2626; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; }
.delete:hover { background: #fee2e2; }
.state { padding: 48px; text-align: center; color: #888; }
</style>
