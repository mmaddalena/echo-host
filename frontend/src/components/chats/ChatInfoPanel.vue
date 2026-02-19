<script setup>
  import { computed, onMounted, ref, nextTick, watch} from 'vue';
  import IconClose from '../icons/IconClose.vue';
  import { formatAddedTime } from "@/utils/formatAddedTime";
  import GroupMemberSelector from "@/components/groups/GroupMemberSelector.vue";
  import IconEdit from '@/components/icons/IconEdit.vue'
  import IconConfirm from '@/components/icons/IconConfirm.vue'
  import IconAdmin from '../icons/IconAdmin.vue';
  import IconImage from '@/components/icons/IconImage.vue';


  const { chatInfo, currentUserId } = defineProps({
    chatInfo: Object,
    currentUserId: String,
  });

  const isGroup = computed(() => chatInfo?.type === 'group');
  const members = computed(() => chatInfo?.members ?? []);

  const isCurrentUserAdmin = computed(() => {
  return members.value.some(
    (m) => m.user_id === currentUserId && m.role === "admin");});

  const emit = defineEmits([
    "close-chat-info-panel", 
    "open-chat", 
    "open-person-info",
    "change-group-name",
    "change-group-description",
    "give-admin",
    "add-members",
    "remove-member",
    "change-group-avatar"
  ]);

  /* -----------------------
  * Add members state
  * --------------------- */
  const showAddMembers = ref(false);
  const newMemberIds = ref([]);

  const existingMemberIds = computed(() =>
    members.value.map((m) => m.user_id)
  );

  function handleClosePanel(){
    emit("close-chat-info-panel");
  }

  function isYou(member_id) {
    return member_id === currentUserId;
  }

  function canRemove(member_id) {
    if (!isCurrentUserAdmin.value) return false;
    if (isYou(member_id)) return false;

    return true;
  }

  function isAdmin(member_id) {
    const member = chatInfo.members.find(m => m.user_id === member_id)
    return member && member.role === "admin"
  }

  function canGiveAdmin(member_id) {
    if (!isCurrentUserAdmin.value) return false;
    if (isYou(member_id)) return false;
    if (isAdmin(member_id)) return false;

    return true;
  }

  async function removeMember(member_id) {
    emit('remove-member', chatInfo.id, member_id)
  }

  function giveAdmin(member_id) {
    emit('give-admin', chatInfo.id, member_id)  
  }

  async function addMembers() {
    if (!newMemberIds.value.length) return;

    emit('add-members', chatInfo.id, newMemberIds.value)

    showAddMembers.value = false;
    newMemberIds.value = [];
  }

  function cancelAddMembers() {
    showAddMembers.value = false;
    newMemberIds.value = [];
  }

  
  const showLeaveConfirm = ref(false)

  function askLeaveGroup() {
    showLeaveConfirm.value = true
  }

  async function confirmLeaveGroup() {
    emit('remove-member', chatInfo.id, currentUserId)
    showLeaveConfirm.value = false
    emit("close-chat-info-panel");
  }

  function handleOpenPersonInfo(member_id) {
    emit('open-person-info', member_id)
  }


  const editingGroupName = ref(false)
  const editingGroupDescription = ref(false)

  const groupName = ref("")
  const groupDescription = ref("")

  const groupNameInput = ref(null)
  const groupDescriptionInput = ref(null)

  watch(
    () => chatInfo,
    (info) => {
      if (!info) {
        handleClosePanel()
        return;
      }
      groupName.value = info.name
      groupDescription.value = info.description ?? ""
    },
    { immediate: true }
  )


  function editGroupName() {
    editingGroupName.value = true
    nextTick(() => groupNameInput.value.focus())
  }

  function confirmGroupName() {
    emit('change-group-name', chatInfo.id, groupName.value)
    editingGroupName.value = false
  }

  function editGroupDescription() {
    editingGroupDescription.value = true
    nextTick(() => {
      groupDescriptionInput.value.focus();
      autoResize(groupDescriptionInput.value);
    })
  }

  function confirmGroupDescription() {
    emit('change-group-description', chatInfo.id, groupDescription.value)
    editingGroupDescription.value = false
  }

  function autoResize(el) {
    if (!el) return
    el.style.height = "1px"
    el.style.height = el.scrollHeight + "px"
  }


const uploadingAvatar = ref(false)
const groupFileInput = ref(null)

function triggerGroupAvatarPicker() {
  if (!isCurrentUserAdmin.value) return
  groupFileInput.value?.click()
}

async function onGroupAvatarSelected(e) {
  const file = e.target.files[0]
  if (!file) return

  if (file.size > 5_000_000) {
    alert("Max 5MB")
    return
  }

  const formData = new FormData()
  formData.append("avatar", file)

  uploadingAvatar.value = true

  try {
    const res = await fetch(
      `http://localhost:4000/api/groups/${chatInfo.id}/avatar`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${sessionStorage.getItem("token")}`,
        },
        body: formData,
      }
    )

    const data = await res.json()

    // Tell parent to update group avatar
    emit("change-group-avatar", chatInfo.id, data.avatar_url)

  } catch (err) {
    console.error("Group avatar upload failed", err)
  } finally {
    uploadingAvatar.value = false
  }
  }

  onMounted(() => {
		editingGroupName.value = false;
    editingGroupDescription.value = false;
    autoResize(groupDescriptionInput.value);
	});

  watch(isCurrentUserAdmin, async (isAdmin) => {
    if (!isAdmin) return

    await nextTick()

    if (groupDescriptionInput.value) {
      autoResize(groupDescriptionInput.value)
    }
  })

</script>

<template>
  <div class="panel">
    <button class="close-btn" @click="handleClosePanel">
      <IconClose />
    </button>

    <div 
    class="avatar-wrapper"
    @click="triggerGroupAvatarPicker"
  >
    <img 
      class="avatar" 
      :src="chatInfo?.avatar_url" 
    />

    <div 
      v-if="isGroup && isCurrentUserAdmin"
      class="avatar-overlay"
    >
      <IconImage class="overlay-icon" />
      <span>
        {{ uploadingAvatar ? "Subiendo..." : "Cambiar imagen" }}
      </span>
    </div>

    <input
      ref="groupFileInput"
      type="file"
      accept="image/*"
      hidden
      @change="onGroupAvatarSelected"
    />
  </div>
    <div class="editable-field" v-if="isGroup && isCurrentUserAdmin">
      <textarea
        ref="groupNameInput"
        class="main-name textarea-edit"
        v-model="groupName"
        :readonly="!editingGroupName"
        @input="autoResize($event.target)"
        rows="1"
      />

      <Transition name="mini-swap" mode="out-in">
        <button
          v-if="!editingGroupName"
          class="edit-button"
          @click="editGroupName"
        >
          <IconEdit class="icon icon-light" />
        </button>

        <button
          v-else
          class="confirm-button"
          @click="confirmGroupName"
        >
          <IconConfirm class="icon" />
        </button>
      </Transition>
    </div>

    <p v-else-if="isGroup" class="main-name">
      {{ chatInfo?.name }}
    </p>


    <div class="editable-field" v-if="isGroup && isCurrentUserAdmin">
      <textarea
        ref="groupDescriptionInput"
        class="description textarea-edit"
        v-model="groupDescription"
        :readonly="!editingGroupDescription"
        @input="autoResize($event.target)"
        rows="1"
      />

      <Transition name="mini-swap" mode="out-in">
        <button
          v-if="!editingGroupDescription"
          class="edit-button"
          @click="editGroupDescription"
        >
          <IconEdit class="icon icon-light" />
        </button>

        <button
          v-else
          class="confirm-button"
          @click="confirmGroupDescription"
        >
          <IconConfirm class="icon" />
        </button>
      </Transition>
    </div>

    <p v-else-if="isGroup" class="description">
      {{ chatInfo?.description }}
    </p>


    <!-- GROUP MEMBERS -->
    <div v-if="isGroup" class="members-section">
      <div class="members-header">
        <p class="members-title">
          Miembros ({{ members.length }})
        </p>

        <button
          v-if="isCurrentUserAdmin && !showAddMembers"
          class="add-member-btn"
          @click="showAddMembers = true"
        >
          Agregar
        </button>
      </div>

      <!-- MEMBER LIST -->
      <ul
        v-if="!showAddMembers"
        class="members-list"
      >
        <li
          v-for="member in members"
          :key="member.user_id"
          class="member-item clickable"
          @click="handleOpenPersonInfo(member.user_id)"
        >
          <!-- LEFT -->
          <div class="member-left">
            <img
              :src="member.avatar_url"
              class="member-avatar"
              loading="lazy"
            />

            <div class="member-info">
              <div class="member-name-row">
                <p class="member-name">
                  {{ member.nickname ?? member.name ?? member.username }}
                </p>

                <span
                  v-if="isYou(member.user_id)"
                  class="you-badge"
                >
                  Tú
                </span>

                <span
                  v-if="member.role === 'admin'"
                  class="admin-badge"
                >
                  Admin
                </span>
              </div>

              <span class="member-status">
                {{ member.status }}
              </span>
            </div>
          </div>

          <!-- RIGHT -->
          <div class="member-buttons">
            <button
              v-if="canGiveAdmin(member.user_id)"
              class="give-admin-btn"
              @click.stop="giveAdmin(member.user_id)"
            >
              <IconAdmin class="admin-icon" />
            </button>
            <button
              v-if="canRemove(member.user_id)"
              class="remove-btn"
              @click.stop="removeMember(member.user_id)"
            >
              <IconClose class="remove-icon"/>
            </button>
          </div>
        </li>
      </ul>

      <!-- ADD MEMBERS UI -->
      <div v-else class="add-members-panel">
        <GroupMemberSelector
          v-model="newMemberIds"
          :existing-member-ids="existingMemberIds"
        />

        <div class="add-members-actions">
          <button
            class="cancel-btn"
            @click="cancelAddMembers"
          >
            Cancelar
          </button>

          <button
            class="confirm-btn"
            :disabled="!newMemberIds.length"
            @click="addMembers"
          >
            Agregar
          </button>
        </div>
      </div>
    </div>

    <Transition name="leave-swap" mode="out-in">
      <!-- ABANDON GROUP BUTTON -->
      <div 
        v-if="isGroup && !showLeaveConfirm" 
        class="leave-group-section"
        key="leave-btn"
      >
        <button class="leave-group-btn" @click="askLeaveGroup">
          Abandonar grupo
        </button>
      </div>

      <!-- ABANDON GROUP CONFIRMATION SECTION -->
      <div 
        v-else 
        class="leave-confirm-box"
        key="leave-confirm"
      >
        <p class="leave-warning">
          ¿Seguro que querés abandonar el grupo?<br>
          No vas a poder volver a ver los mensajes antiguos.
        </p>

        <div class="leave-confirm-actions">
          <button class="cancel-btn" @click="showLeaveConfirm = false">
            Cancelar
          </button>

          <button class="confirm-leave-btn" @click="confirmLeaveGroup">
            Abandonar grupo
          </button>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>

.panel {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  background-color: var(--bg-peoplelist-panel);
  width: 100%;

  height: 100%;
  overflow-y: auto;
}
.close-btn {
  all: unset;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: var(--bg-main);
  height: 4rem;
  width: 4rem;
  border-radius: 50%;
  border: none;

  padding: 1rem;
  box-sizing: border-box;

  position: absolute;
  top: 1rem;
  right: 1rem;
  cursor: pointer;

  font-size: 2rem;
  color: var(--text-main);
}


/* .avatar {
  width: 15rem;
  height: 15rem;
  border-radius: 50%;
  margin: 4rem auto 2rem auto;
  object-fit: cover;
  object-position: center;
} */
.main-name {
  color: var(--text-main) !important;
  font-size: 2.2rem !important;
  font-weight: bold !important;
  text-align: center !important;
  padding-top: 0.6rem !important;
  padding-bottom: 0.6rem !important;

  display: flex;
  width: calc(100% - 7rem - 7rem);
	gap: 1rem;
  align-items: center;
  margin-left: 7rem;
  margin-right: 7rem;
  margin-bottom: 2rem;
}
.description {
  font-size: 1.6rem !important;
  color: var(--text-muted) !important;
  text-align: start !important;

  display: flex;
  width: calc(100% - 7rem - 7rem);
	gap: 1rem;
  align-items: center;
  margin-left: 7rem;
  margin-right: 7rem;
}
.added-date {
  margin-top: 1rem;
  font-size: 1.5rem;
  color: var(--text-muted);
}


.editable-field {
	display: flex;
  width: calc(100% - 4rem - 4rem);
	gap: 1rem;
  align-items: center;
  margin-left: 4rem;
}

.textarea-edit {
  all: unset;
  flex: 1;
  min-width: 0;
  width: 100%;

  line-height: 1.4;
  color: var(--text-main);

  padding: 0.6rem 0.8rem;
  border-radius: 0.8rem;

  border: 1px solid #2f3e63;

  resize: none;
  overflow: hidden;
  white-space: pre-wrap;
}

.textarea-edit[readonly] {
  background: none;
  border: 1px solid rgba(255, 0, 0, 0);
  padding: 0.6rem 0.8rem;
}


.edit-button {
	all: unset;
	height: 3rem;
	width: 3rem;
	border-radius: 50%;
	background-color: var(--main-app-color-2);
  color: var(--text-main-light);
	display: flex;
	align-items: center;
	justify-content: center;
}
.confirm-button {
	all: unset;
	height: 3rem;
	width: 3rem;
	border-radius: 50%;
	background-color: var(--main-app-color-1);
  color: var(--text-main-light);
	display: flex;
	align-items: center;
	justify-content: center;
}
.icon {
	max-height: 2.2rem;
	max-width: 2.2rem;
	color: var(--text-main);
}
.icon-light {
 color: var(--text-main-light) !important; 
}

.mini-swap-enter-active,
.mini-swap-leave-active {
	transition: opacity 0.15s ease, transform 0.15s ease;
}
.mini-swap-enter-from {
	opacity: 0;
	transform: scale(0.85);
}
.mini-swap-leave-to {
	opacity: 0;
	transform: scale(0.85);
}




button {
  border: none;
  border-radius: 20px;
  padding: 6px 16px;
  font-size: 14px;
  cursor: pointer;
  background-color: var(--main-app-color-2);
}

.members-section {
  width: 100%;
  margin-top: 2rem;
  padding: 0 1.5rem;
  
  max-height: 30vh;
  /* min-height: 0; */
  /* flex: 1; */
  min-height: 0;
  overflow-y: auto;

  flex-shrink: 0;
}

.members-title {
  font-size: 1.6rem;
  font-weight: bold;
  color: var(--text-main);
  margin-bottom: 1rem;
}

.members-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.member-item {
  display: flex;
  align-items: center;
  padding: 0.6rem 0.8rem;
  justify-content: space-between;
  cursor: pointer;
}

.member-left {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex: 1;
  min-width: 0;
}


.member-buttons {
  display: flex;
  gap: 0.8rem;
}
.give-admin-btn {
  border: none;
  background: transparent;
  color: var(--accent);
  font-size: 1.6rem;
  cursor: pointer;
  padding: 0.4rem;
  border-radius: 0.5rem;
}
.give-admin-btn:hover {
  background-color: var(--accent-hover);
}
.admin-icon {
  height: 1.8rem;
}

.remove-btn {
  border: none;
  background: transparent;
  color: tomato;
  font-size: 1.6rem;
  cursor: pointer;
  padding: 0.4rem;
  border-radius: 0.5rem;
}
.remove-btn:hover {
  background-color: rgba(255, 99, 71, 0.15);
}
.remove-icon {
  height: 1.8rem;
}


.member-item:hover {
  background-color: var(--bg-chatlist-hover);
  border-radius: 0.8rem;
}

.member-name-row {
  display: flex;
  align-items: center;
  gap: 0.6rem;
}

.you-badge {
  font-size: 1.1rem;
  padding: 0.1rem 0.6rem;
  border-radius: 1rem;
  background-color: var(--accent);
  color: white;
}

.admin-badge {
  font-size: 1.1rem;
  padding: 0.1rem 0.6rem;
  border-radius: 1rem;
  background-color: #f59e0b;
  color: white;
}

.member-avatar {
  width: 3.2rem;
  height: 3.2rem;
  border-radius: 50%;
}

.member-info {
  display: flex;
  flex-direction: column;
}

.member-name {
  font-size: 1.5rem;
}

.member-status {
  font-size: 1.3rem;
  color: var(--text-muted);
}

.members-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.add-members-actions {
  display: flex;
  justify-content: end;
  align-items: center;
}

.cancel-btn {
  margin: 1rem;
  background-color: var(--bg-chatlist-panel);
  color: var(--text-main)
}

.leave-group-section {
  margin-top: 3rem;
  width: 100%;
  display: flex;
  justify-content: center;
}
.leave-group-btn {
  background-color: var(--main-app-color-2);
  color: var(--text-main-light) !important;
}



/* SCROLLS */
/* PANEL SCROLL */
.panel::-webkit-scrollbar,
.members-section::-webkit-scrollbar {
  width: 0.8rem;
}

.panel::-webkit-scrollbar-track,
.members-section::-webkit-scrollbar-track {
  background: transparent;
}

.panel::-webkit-scrollbar-thumb,
.members-section::-webkit-scrollbar-thumb {
  background: var(--scroll-bar);
  border-radius: 999px;
}

.panel::-webkit-scrollbar-thumb:hover,
.members-section::-webkit-scrollbar-thumb:hover {
  background: var(--scroll-bar-hover);
}

.panel::-webkit-scrollbar-button,
.members-section::-webkit-scrollbar-button {
  display: none;
}

.leave-confirm-box {
  margin-top: 1.5rem;
  padding: 1.2rem;
  border-radius: 1rem;
  background: var(--bg-warning-panel);
  color: white;
  text-align: center;
  box-shadow: inset 0 0 8px rgba(255, 0, 0, 0.4);
  margin-bottom: 2rem;
}

.leave-warning {
  font-size: 1.4rem;
  margin-bottom: 1rem;
  color: var(--text-main)
}

.leave-confirm-actions {
  display: flex;
  justify-content: center;
  gap: 1rem;
}

.confirm-leave-btn {
  background: var(--bg-warning-button);
  color: white;
  height: fit-content;
  padding: 1rem 1.5rem;
}

.leave-confirm-actions .cancel-btn {
  margin: 0;
  height: fit-content;
  padding: 1rem 1.5rem;
  background-color: var(--bg-chatlist-panel);
  color: var(--text-main)
}

.leave-swap-enter-active,
.leave-swap-leave-active {
  transition: opacity 0.1s ease, transform 0.1s ease;
}
.leave-swap-enter-from {
  opacity: 0;
  transform: translateY(6px) scale(0.97);
}
.leave-swap-leave-to {
  opacity: 0;
  transform: translateY(-6px) scale(0.97);
}

.avatar-wrapper {
  position: relative;
  width: 15rem;
  height: 15rem;
  margin: 4rem auto 2rem auto;
  cursor: pointer;
}

.avatar-wrapper .avatar {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  object-fit: cover;
  transition: filter 0.2s ease;
}

/* Overlay */
.avatar-overlay {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.55);

  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;

  color: white;
  font-size: 1.4rem;
  gap: 0.6rem;

  opacity: 0;
  transition: opacity 0.2s ease;
}

/* Hover effect */
.avatar-wrapper:hover .avatar-overlay {
  opacity: 1;
}

.avatar-wrapper:hover .avatar {
  filter: brightness(0.6);
}

.overlay-icon {
  height: 2.4rem;
}

</style>