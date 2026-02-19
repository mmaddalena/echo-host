<script setup>
  import ProfileSettings from "@/components/settings/sections/ProfileSettings.vue";
  import PrivacySettings from "@/components/settings/sections/PrivacySettings.vue";
  import NotificationsSettings from "@/components/settings/sections/NotificationsSettings.vue";
</script>

<template>
  <div class="settings-scroll">
    <section id="profile">
      <ProfileSettings />
    </section>

    <!-- <section id="privacy">
      <PrivacySettings />
    </section>

    <section id="notifications">
      <NotificationsSettings />
    </section> -->
</div>

</template>

<style scoped>
.settings-scroll {
  height: 100%;
  overflow-y: auto;
  scroll-behavior: smooth;
  padding: 6rem 0 5rem 2rem;
}

</style>