<script setup>
import { ref } from "vue";

const username = ref("Manu");
const status = ref("Activo");
</script>

<template>
  <section id="profile" class="settings-section">
    <h2>Privacidad</h2>
    
  </section>
</template>

<style scoped>
.settings-section {
  padding: 2.4rem 0;
}

h2 {
  margin-bottom: 2rem;
  font-size: 2rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  margin-bottom: 1.6rem;
}

label {
  font-size: 1.3rem;
  color: var(--text-muted);
}

input {
  background: none;
  border: 1px solid #2f3e63;
  border-radius: 0.8rem;
  padding: 0.8rem;
  color: var(--text-main);
}

.save {
  margin-top: 1.6rem;
  padding: 0.8rem 1.6rem;
  border-radius: 1rem;
  background: var(--msg-out);
  border: none;
  cursor: pointer;
}
</style>
