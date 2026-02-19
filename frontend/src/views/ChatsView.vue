<script setup>
import { computed, onMounted, watch, nextTick, ref} from "vue";

import { useSocketStore } from "@/stores/socket";
import { storeToRefs } from "pinia";

import Sidebar from "@/components/layout/Sidebar.vue";
import ChatList from "@/components/chats/ChatList.vue";
import ChatHeader from "@/components/chats/ChatHeader.vue";
import ChatMessages from "@/components/chats/ChatMessages.vue";
import ChatInput from "@/components/chats/ChatInput.vue";
import ChatInfoPanel from "@/components/chats/ChatInfoPanel.vue";
import PersonInfoPanel from "@/components/people/PersonInfoPanel.vue";
import { getCurrentISOTimeString } from "@/utils/formatChatTime";
import { generateId } from "@/utils/idGenerator";

import { useUIStore } from "@/stores/ui";
import PeoplePanel from "@/components/people/PeoplePanel.vue";
import ChatPanel from "@/components/chats/ChatPanel.vue";

import { useThemeStore } from "@/stores/theme"
import logoLight from "@/assets/logo/Echo_Logo_Completo.svg";
import logoDark from "@/assets/logo/Echo_Logo_Completo_Negativo.svg";


const themeStore = useThemeStore()
const theme = computed(() => themeStore.theme)


const socketStore = useSocketStore();
const uiStore = useUIStore();

const { userInfo } = storeToRefs(socketStore);
const { chatsInfo } = storeToRefs(socketStore);
const { activeChatId } = storeToRefs(socketStore);
const { pendingPrivateChat } = storeToRefs(socketStore);
const { openedPersonInfo } = storeToRefs(socketStore);

const chatMessagesRef = ref(null);

const chatInputRef = ref(null);

onMounted(() => {
	const token = sessionStorage.getItem("token");
	if (token) {
		socketStore.connect(token);
	}

	uiStore.showChats();
	console.log("Se montó la chatsview y se mostraron los chats");
});

const activeChat = computed(() => {
	if (pendingPrivateChat.value != null) {
		return {
			id: null,
			type: "private",
			name: pendingPrivateChat.value.name,
			username: pendingPrivateChat.value.username,
			avatar_url: pendingPrivateChat.value.avatar_url,
			status: pendingPrivateChat.value.status,
			messages: [],
		};
	}

	if (activeChatId.value) {
		return chatsInfo.value[activeChatId.value];
	}

	return null;
});

const messages = computed(() => activeChat.value?.messages ?? []);
const chatType = computed(() => activeChat.value?.type ?? null);

const panel = computed(() => uiStore.leftPanel);

const isPendingChat = computed(() => pendingPrivateChat.value != null);

function handleSendMessage(text) {
	if (isPendingChat.value) {
		socketStore.createPrivateChatAndSendMessage({
			id: null,
			front_msg_id: generateId(),
			chat_id: null, // Lo pisamos en el socket cuando se vaya a mandar
			content: text,
			state: "sending", // Cuando se guarde en el back se pisa por sent
			sender_user_id: userInfo.value.id,
			type: "outgoing",
			time: getCurrentISOTimeString(), // Despues se pisa con el inserted_at del back
			avatar_url: userInfo.value.avatar_url,
			format: "text",
		});
		return;
	}

	if (!activeChatId.value) return;

	socketStore.sendMessage({
		id: null,
		front_msg_id: generateId(),
		chat_id: activeChatId.value,
		content: text,
		state: "sending", // Cuando se guarde en el back se pisa por sent
		sender_user_id: userInfo.value.id,
		type: "outgoing",
		time: getCurrentISOTimeString(), // Despues se pisa con el inserted_at del back
		avatar_url: userInfo.value.avatar_url, // TODO: POR QUE MANDA ESTO??? CREO QUE HAY QUE SACARLO
		format: "text",
	});
}

async function handleSendAttachment(file) {
	if (!activeChatId.value) return;

	const token = sessionStorage.getItem("token");

	const formData = new FormData();
	formData.append("file", file);

	// 1. Upload via HTTP
	const res = await fetch("/api/chat/upload", {
		method: "POST",
		headers: {
			Authorization: `Bearer ${token}`,
		},
		body: formData,
	});

	console.log(res);

	if (!res.ok) return;

	const { url, mime } = await res.json();

	// 2. Send message via WebSocket
	socketStore.sendMessage({
		id: null,
		front_msg_id: generateId(),
		chat_id: activeChatId.value,
		content: url,
		mime,
		filename: file.name,
		state: "sending",
		sender_user_id: userInfo.value.id,
		type: "outgoing",
		format: mime.startsWith("image/") ? "image" : "file",
		time: getCurrentISOTimeString(),
		avatar_url: userInfo.value.avatar_url,
	});
}

function scrollToMessage(messageId) {
	chatMessagesRef.value?.scrollToMessage(messageId);
}

function handleOpenChatInfo(chatInfo) {
	if (chatInfo.type === 'private') {
		handleOpenPersonInfo(socketStore.getOtherMemberId(chatInfo))
	} if (chatInfo.type === 'group') {
		uiStore.showChatInfo();
	}
}


function handleOpenPersonInfo(person_id) {
	uiStore.showPersonInfo()
	socketStore.getPersonInfo(person_id);
}

watch(activeChatId, async (newVal) => {
	if (!newVal) return;
	await nextTick();
	chatInputRef.value?.clear();
	chatInputRef.value?.focusInput();
});

watch(
	panel,
	(pan) => {
		console.log(`El panel activo es: ${pan}`);
	},
);


function handleChangeGroupName(chat_id, new_name) {
	socketStore.changeGroupName(chat_id, new_name)
}

function handleChangeGroupDescription(chat_id, new_description) {
	socketStore.changeGroupDescription(chat_id, new_description)
}

function handleGiveAdmin(chat_id, member_id) {
	socketStore.giveAdmin(chat_id, member_id)
}

function handleCloseChatInfo() {
	uiStore.closePanel()
}


  function closePersonInfoPanel() {
    //contactSearchText.value = null;
    socketStore.deletePersonInfo();
    //socketStore.deletePeopleSearchResults();
    uiStore.closePanel();
  }

  function handleOpenChat(chatId) {
    if (chatId) {
      socketStore.openChat(chatId)
    } else {
      socketStore.openPendingPrivateChat(openedPersonInfo)
    }
  }

  function handleChangeNickname(personId, newNickname) {
    socketStore.changeNickname(personId, newNickname)
  }

  function handleAddContact(personId) {
    socketStore.addContact(personId)
  }

  function handleDeleteContact(personId) {
    socketStore.deleteContact(personId)
  }

  function handleAddMembers(chatId, memberIds) {
		socketStore.addMembers(chatId, memberIds)
  }

  function handleRemoveMember(chatId, memberId) {
		socketStore.removeMember(chatId, memberId)
  }
</script>

<template>
	<div class="chats-layout">
		<div class="left">
			<img
				:src="theme === 'dark' ? logoDark : logoLight"
				class="logo"
				alt="Echo logo"
			/>
			<div class="main">
				<Sidebar :avatarURL="userInfo?.avatar_url" />
				<ChatPanel v-if="panel === 'chats'" />
				<PeoplePanel v-if="panel === 'people'" />
				<ChatInfoPanel
					v-if="panel === 'chat-info'"
					:chatInfo="activeChat"
					:currentUserId="userInfo.id"
					@close-chat-info-panel="handleCloseChatInfo"
					@open-person-info="handleOpenPersonInfo"
					@change-group-name="handleChangeGroupName"
					@change-group-description="handleChangeGroupDescription"
					@give-admin="handleGiveAdmin"
					@add-members="handleAddMembers"
					@remove-member="handleRemoveMember"
				/>
				<PersonInfoPanel
					v-if="panel === 'person-info' && openedPersonInfo != null"
					:personInfo="openedPersonInfo"
					:currentUserId="userInfo.id"
					@close-person-info-panel="closePersonInfoPanel"
					@open-chat="handleOpenChat"
					@change-nickname="handleChangeNickname"
					@add-contact="handleAddContact"
					@delete-contact="handleDeleteContact"
				/>
			</div>
		</div>
		<div class="right">
			<ChatHeader
				:chatInfo="activeChat"
				:last_seen_at="userInfo?.last_seen_at"
				:currentUserId="userInfo?.id"
				@scroll-to-message="scrollToMessage"
				@open-chat-info="handleOpenChatInfo"
			/>
			<ChatMessages
				:messages="messages"
				:chatType="chatType"
				ref="chatMessagesRef"
			/>
			<ChatInput
				ref="chatInputRef"
				@send-message="handleSendMessage"
				@send-attachment="handleSendAttachment"
			/>
		</div>
	</div>
</template>

<style scoped>
.chats-layout {
	display: flex;
	flex-direction: row;
	height: 100vh;
}
.left {
	display: flex;
	flex-direction: column;
	align-items: flex-start;
	height: 100%;
	width: var(--left-section-width);
}
.logo {
	height: 6rem;
	margin: 2rem;
}
.main {
	display: flex;
	flex-direction: row;
	flex: 1;
	width: 100%;
	min-height: 0; 
}
.right {
	display: flex;
	flex-direction: column;
	flex: 1;
	height: 100%;
}
</style>
