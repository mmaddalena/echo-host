<script setup>
  function go(id) {
    document
      .getElementById(id)
      ?.scrollIntoView({ behavior: "smooth" });
  }

</script>

<template>
  <ul>
    <li @click="go('profile')">Perfil</li>
    <!-- <li @click="go('privacy')">Privacidad</li>
    <li @click="go('notifications')">Notificaciones</li> -->

    <li class="logout" @click="$emit('logout')">
      Cerrar sesión
    </li>
</ul>

</template>

<style scoped>
ul {
  list-style: none;
  padding: 1rem 0 0 0;
  margin: 0;
  width: 100%;
  background-color: var(--bg-chat);
  display: flex;
  flex-direction: column;
}

li {
  padding: 1.2rem 1.6rem;
  margin: 0 1rem;
  cursor: pointer;
  font-size: 1.4rem;
  color: var(--text-main);
  border-radius: 0.8rem;
  transition: "background" 0.15s ease, color 0.15s ease;
}
li:hover {
  background: var(--bg-chatlist-hover);
}

.logout {
  margin-top: auto;
  margin-bottom: 1rem;
  color: var(--text-main-light);
  background-color: var(--bg-logout);
  width: fit-content;
}
.logout:hover {
  background: rgb(182, 75, 75);
}


</style>