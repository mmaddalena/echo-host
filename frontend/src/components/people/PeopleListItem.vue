<script setup>
  const { person } = defineProps({
    person: Object,
  });

  const emit = defineEmits(["get-person-info"]);

  function handleClick(){
    emit("get-person-info", person.id);
  }
  
</script>

<template>
  <div class="person-item" @click="handleClick">
    <img class="avatar" :src="person.avatar_url"/>
    <div class="info">
      <div class="names">
        <p class="main-name">
          {{ person.contact_info?.nickname ?? person.name ??  person.username }}
        </p>
        <p class="second-name">
          {{ person.username }}
        </p>
      </div>
      <!-- otra cosa eventualmente -->
    </div>
  </div>
</template>

<style scoped>
.person-item {
  display: flex;
  gap: 12px;
  padding: 12px;
  cursor: pointer;
}
.person-item:hover {
  background: var(--bg-peoplelist-hover);
  border-radius: 1.5rem;
}
.avatar {
  height: 5rem;
  width: 5rem;
  background-color: none;
  border-radius: 50%;
}
.info {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}
.main-name {
  color: var(--text-main);
  font-weight: 600;
  margin-right: 1.5rem;
}
.second-name {
  font-size: 1.4rem;
  color: var(--text-muted);
}
</style>