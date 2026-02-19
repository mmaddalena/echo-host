<script setup>
  import { computed, ref, watch, onMounted, nextTick } from 'vue';
  import IconClose from '@/components/icons/IconClose.vue';
  import IconChats from '@/components/icons/IconChats.vue';
  import IconEdit from '@/components/icons/IconEdit.vue';
  import IconConfirm from '@/components/icons/IconConfirm.vue';
  import IconAddContact from '@/components/icons/IconAddContact.vue';
  import IconDeleteContact from '@/components/icons/IconDeleteContact.vue';
  import { formatAddedTime } from "@/utils/formatAddedTime";

  const {personInfo, currentUserId} = defineProps({
    personInfo: {
      type: Object,
      required: true
    },
    currentUserId: {
      type: Number
    }
  })

  const emit = defineEmits(["close-person-info-panel", "open-chat", "change-nickname", "add-contact", "delete-contact"]);

  function handleClosePanel(){
    emit("close-person-info-panel");
  }

  function handleSendMsg(){
    emit("open-chat", personInfo.private_chat_id);
  }

  const isContact = computed(() => personInfo.contact_info != null);


  const nickname = ref("")
  const nicknameInput = ref(null)

	watch(
		() => personInfo,
		(info) => {
			if (!info) return
			nickname.value = info.contact_info?.nickname ?? personInfo.name
		},
		{ immediate: true }
	)

  const editingNickname = ref(false)
  onMounted(() => {
		editingNickname.value = false;
	});

  function handleEditNicknameMode() {
		editingNickname.value = true;
    nickname.value = personInfo.contact_info?.nickname ?? personInfo.name;
    nextTick(() => {
      nicknameInput.value.focus()
    })
	}

	function handleConfirmEditNickname() {
		emit("change-nickname", personInfo.id, nickname.value)
		editingNickname.value = false;
	}

  function handleAddContact() {
    emit("add-contact", personInfo.id)
  }

  function handleDeleteContact(){
    emit("delete-contact", personInfo.id)
  }

  const isYou = computed(() => {
    return personInfo.id == currentUserId
  })
</script>

<template>
  <div class="panel">
    <button class="close-btn" @click="handleClosePanel">
      <IconClose />
    </button>
    <img class="avatar" :src="personInfo.avatar_url"></img>
    <div class="editable-field" v-if="isContact">
      <input 
        ref="nicknameInput"
        class="main-name"
        v-model="nickname" 
        :type="editingNickname ? 'text' : 'text'" 
        :readonly="!editingNickname"
      />
      <Transition name="mini-swap" mode="out-in">
        <button 
          v-if="!editingNickname"
          class="edit-button" 
          @click="handleEditNicknameMode()"
        >
          <IconEdit class="icon"/>
        </button>
        <button 
          v-else
          class="confirm-button" 
          @click="handleConfirmEditNickname()"
        >
          <IconConfirm class="icon"/>
        </button>
      </Transition>
    </div>
    <div v-else-if="personInfo.name" class="main-name" >
      {{personInfo.name}}
    </div>

    <p class="second-name">
      {{ personInfo.username}}
    </p>

    <p v-if="isContact" class="added-date">
      <!-- Agregado {{ formatAddedTime(personInfo.contact_info?.added_at) }} -->
       <p v-if="personInfo.status == 'Offline' && personInfo.last_seen_at">
          Última vez activo:
          {{ formatAddedTime(personInfo.last_seen_at) }}
       </p>
       <p v-else>
         Estado: {{ personInfo.status }}
         </p>
    </p>

    <div class="buttons">
      <button class="btn" @click="handleSendMsg">
        <IconChats class="btn-icon" />
        <p class="btn-text">
          Enviar Mensaje
        </p>
      </button>

      <button 
        v-if="!isYou && !isContact"
        class="btn" 
        @click="handleAddContact"
      >
        <IconAddContact class="btn-icon" />
        <p class="btn-text">
          Añadir Contacto
        </p>
      </button>

      <button 
        v-else-if="!isYou"
        class="btn" 
        @click="handleDeleteContact"
      >
        <IconDeleteContact class="btn-icon" />
        <p class="btn-text">
          Eliminar Contacto
        </p>
      </button>


     
    </div>

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
}
.close-btn {
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: var(--bg-main);
  height: 4rem;
  width: 4rem;
  border-radius: 50%;
  border: none;

  padding: 1rem;

  position: absolute;
  top: 1rem;
  right: 1rem;
  cursor: pointer;

  font-size: 2rem;
  color: var(--text-main);
}

.avatar {
  width: 50%;
  border-radius: 50%;
  margin: 4rem auto 2rem auto;
}
.main-name {
  font-size: 2.2rem;
  font-weight: bold;
}
.second-name {
  font-size: 1.8rem;
  color: var(--text-muted);
}
.added-date {
  margin-top: 1rem;
  font-size: 1.5rem;
  color: var(--text-muted);
}

.buttons {
  margin-top: 2rem;
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  justify-content: center;
}
.btn {
  all: unset;
  width: auto;
  height: fit-content;
  background-color: var(--msg-out);
  border-radius: 1rem;
  padding: 0.5rem 1rem;
  cursor: pointer;

  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.btn-icon {
  height: 3.5rem;
}
.btn-text {
  font-size: 1.4rem;
}



.editable-field {
	display: flex;
	gap: 1rem;
  align-items: center;
  margin-left: 4rem;
}

input {
	background: none;
	border: 1px solid #2f3e63;
	border-radius: 0.8rem;
	padding: 0.8rem;
	color: var(--text-main);
	font-size: 2.2rem;
  text-align: center;
}
input[readonly] {
	border: none;
	cursor: text;
	opacity: 0.85;
	outline: none;
}
input:not([readonly]) {
	border: 1px solid #2f3e63;
}

.edit-button {
	all: unset;
	height: 3rem;
	width: 3rem;
	border-radius: 50%;
	background-color: var(--msg-out);
	display: flex;
	align-items: center;
	justify-content: center;
}
.confirm-button {
	all: unset;
	height: 3rem;
	width: 3rem;
	border-radius: 50%;
	background-color: var(--msg-in);
	display: flex;
	align-items: center;
	justify-content: center;
}
.icon {
	max-height: 2.2rem;
	max-width: 2.2rem;
	color: var(--text-main);
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

</style>