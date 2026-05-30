import { createApp } from 'vue';
import { createRouter, createWebHistory } from 'vue-router';
import App from './App.vue';
import LoginView from './views/LoginView.vue';
import UsersView from './views/UsersView.vue';
import AnalyticsView from './views/AnalyticsView.vue';
import CategoriesView from './views/CategoriesView.vue';
import ActsView from './views/ActsView.vue';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', component: LoginView, meta: { public: true } },
    { path: '/', redirect: '/analytics' },
    { path: '/analytics', component: AnalyticsView },
    { path: '/users', component: UsersView },
    { path: '/categories', component: CategoriesView },
    { path: '/acts', component: ActsView },
  ],
});

router.beforeEach((to) => {
  const token = localStorage.getItem('auth_token');
  if (!to.meta.public && !token) return '/login';
});

createApp(App).use(router).mount('#app');
