import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '@/views/LoginView.vue'
import RegisterView from '@/views/RegisterView.vue'
import ChatsView from '@/views/ChatsView.vue'
import SettingsView from '../views/SettingsView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { 
      path: '/', 
      redirect: '/login'
    },
    { 
      path: '/login', 
      name: "login",
      component: LoginView,
      meta: { guestOnly: true }
    },
    { 
      path: '/register', 
      name: "register",
      component: RegisterView,
      meta: { guestOnly: true }
    },
    { 
      path: '/chats', 
      name: "chats",
      component: ChatsView,
      meta: { requiresAuth: true }
    },
    {
      path: '/settings',
      name: "settings",
      component: SettingsView,
      meta: { requiresAuth: true }
    }
  ]
})

router.beforeEach((to, from) => {
  console.log("GUARD", {
    to: to.path,
    token: sessionStorage.getItem("token")
  });
});

router.beforeEach((to, from, next) => {
  const token = sessionStorage.getItem("token");

  if (to.meta.requiresAuth && !token) {
    // No logeado → login
    next("/login");
  } else if (to.meta.guestOnly && token) {
    // Ya logeado → chats
    next("/chats");
  } else {
    next();
  }
});


export default router
