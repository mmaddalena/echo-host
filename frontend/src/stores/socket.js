import { defineStore } from "pinia";
import { ref } from "vue";
import { generateId } from "@/utils/idGenerator";
import { useThemeStore } from "@/stores/theme"


export const useSocketStore = defineStore("socket", () => {
	const socket = ref(null);
	const userInfo = ref(null);
	const chats = ref([]);
	const chatsInfo = ref({});
	const activeChatId = ref(null);
	const contacts = ref([]);
	const contactsLoaded = ref(false);
	const openedPersonInfo = ref(null);
	const peopleSearchResults = ref(null);
	const pendingPrivateChat = ref(null);
	const pendingMessage = ref(null);
	const themeStore = useThemeStore();

	const creatingGroup = ref(false);
	const selectedGroupMembers = ref([]);
	const newGroupInfo = ref({
		name: "",
		description: "",
		avatar: null, // File or uploaded URL
	});

	function connect(token) {
		if (socket.value) return; // ya conectado

		const protocol = location.protocol === "https:" ? "wss" : "ws";
		socket.value = new WebSocket(
			// `${protocol}://${location.host}/ws?token=${token}`,
			`http://localhost:4000/ws?token=${token}`,
		);

		socket.value.onopen = () => {
			console.log("WS conectado");

			const savedChatId = sessionStorage.getItem("activeChatId");
			if (savedChatId) {
				activeChatId.value = savedChatId;
				send({
					type: "open_chat",
					chat_id: savedChatId,
				});
			}
		};

		socket.value.onmessage = (event) => {
			const payload = JSON.parse(event.data);

			if (payload.type === "user_info") {
				dispatch_user_info(payload);
			} else if (payload.type === "chat_info") {
				dispatch_chat_info(payload);
			} else if (payload.type === "new_message") {
				dispatch_new_message(payload);
			} else if (payload.type === "chat_read") {
				dispatch_chat_read(payload);
			} else if (payload.type === "messages_delivered") {
				markMessagesDelivered(payload.message_ids);
			} else if (payload.type === "contacts") {
				contacts.value = payload.contacts;
				contactsLoaded.value = true;
			} else if (payload.type === "person_info") {
				openedPersonInfo.value = payload.person_info;
			} else if (payload.type === "search_people_results") {
				peopleSearchResults.value = payload.search_people_results;
			} else if (payload.type === "private_chat_created") {
				dispatch_private_chat_created(payload)
			} else if (payload.type === "username_change_result") {
				dispatch_change_username(payload);
			} else if (payload.type === "name_change_result") {
				dispatch_change_name(payload);
			} else if (payload.type === "nickname_change_result") {
				dispatch_change_nickname(payload);
			} else if (payload.type === "group_chat_created") {
				dispatch_group_created(payload);
			} else if (payload.type === "contact_addition") {
				dispatch_contact_addition(payload)
			} else if (payload.type === "contact_deletion") {
				dispatch_contact_deletion(payload)
			} else if (payload.type === "chat_member_removed") {
				dispatch_chat_member_removed(payload);
			} else if (payload.type === "chat_members_added") {
				dispatch_chat_member_added(payload);
			} else if (payload.type === "chat_added") {
				chats.value = [payload.chat_item, ...chats.value];
			} else if (payload.type === "chat_forbidden") {
				if (activeChatId.value === payload.chat_id) {
					activeChatId.value = null;
					sessionStorage.removeItem("activeChatId");
				}
				chats.value = chats.value.filter(c => c.id !== payload.chat_id);
				const { [payload.chat_id]: _, ...rest } = chatsInfo.value;
				chatsInfo.value = rest;
			} else if (payload.type === "chat_admin_changed") {
				dispatch_chat_admin_changed(payload);
			} else if (payload.type === 'group_name_change_result') {
				dispatch_group_name_changed(payload)
			} else if (payload.type === 'group_description_change_result') {
				dispatch_group_description_changed(payload)
			} else if (payload.type === 'admin_given_to_member') {
				dispatch_admin_given_to_member(payload)
			} else if (payload.type === 'group_avatar_updated') {
				console.log(`Payload de group avatar updated: `, payload);
				dispatch_group_avatar_updated(payload)
			}
		};

		socket.value.onerror = () => {
			console.error("Error en WS");
		};
	}

	function dispatch_user_info(payload) {
		userInfo.value = payload.user;
		chats.value = payload.last_chats ?? [];
	}
	function dispatch_chat_info(payload) {
		const chat = payload.chat;

		const normalizedMessages = chat.messages.map((m) => ({
			...m,
			front_msg_id: generateId(),
		}));

		chatsInfo.value = {
			...chatsInfo.value,
			[chat.id]: {
				...chat,
				messages: normalizedMessages,
			},
		};
		activeChatId.value = chat.id;

		// Seteamos como read los incoming
		setReadIncomingMessages(chat.id);

		// Actualizamos el ChatListItem
		const lastMsg = getLastMessage(chat);

		updateChatListItem(lastMsg);
	}
	function dispatch_new_message(payload) {
		const msg = payload.message;
		const chatId = msg.chat_id;
		console.log(`LLegó un nuevo mensaje '${msg.content}'`)

		// Actualizo la lista de chats
		chats.value = chats.value.map((chat) => {
			if (chat.id !== chatId) return chat;
			const isIncoming = msg.user_id !== userInfo.value.id;
			return {
				...chat,
				last_message: {
					type: isIncoming ? "incoming" : "outgoing",
					content: msg.content,
					state: msg.state,
					time: msg.time,
					avatar_url: msg.avatar_url,
					format: msg.format,
					filename: msg.filename,
				},
				unread_messages: isIncoming
					? chat.unread_messages + 1
					: chat.unread_messages,
			};
		});

		// Ahora sí, actualizo la caché de chatsInfo
		if (msg.user_id == userInfo.value.id) {
			// El mensaje es outgoing...
			const index = chatsInfo.value[chatId].messages.findIndex(
				(m) => m.front_msg_id === msg.front_msg_id,
			);

			if (index !== -1) {
				// Por safety nomás, debería entrar sí o sí
				Object.assign(chatsInfo.value[chatId].messages[index], msg);
			}
			console.log(`Mensaje outgoing recibido: `, msg);
		} else {
			// El mensaje es incoming...
			const normalizedMsg = {
				...msg,
				front_msg_id: msg.front_msg_id ?? generateId(),
			};

			const chat = chatsInfo.value[chatId];

			if (chat) {
				chatsInfo.value = {
					...chatsInfo.value,
					[chatId]: {
						...chat,
						messages: [...chat.messages, normalizedMsg],
					},
				};
			}

			// Si tengo este chat abierto
			if (normalizedMsg.chat_id == activeChatId.value) {
				// Notifico al back que leí el mensaje
				send({
					type: "chat_messages_read",
					chat_id: chatId,
				});

				// Seteamos como read los incoming
				setReadIncomingMessages(chatId);

				// Actualizamos el ChatListItem también
				updateChatListItem(normalizedMsg);
			}
		}
	}
	function dispatch_chat_read(payload) {
		const chat_id = payload.chat_id;
		const chat = chatsInfo.value[chat_id];

		if (!chat || chat.type != "private") return;

		chatsInfo.value = {
			...chatsInfo.value,
			[chat_id]: {
				...chat,
				messages: chat.messages.map((m) =>
					m.type === "outgoing" && m.state !== "read"
						? { ...m, state: "read" }
						: m,
				),
			},
		};

		const lastMsg = getLastMessage(chatsInfo.value[chat_id]);
		if (lastMsg) {
			updateChatListItem({ ...lastMsg, state: "read" });
		}
	}

	function dispatch_private_chat_created(payload) {
		// Meto la info en la caché de los chats
		chats.value = [payload.chat_item, ...chats.value];
		if (pendingPrivateChat.value != null) {
			console.log(`Se creó el chat privado con id: ${payload.chat.id}`);

			dispatch_chat_info(payload);
			// Mando el mensaje pendiente
			const msg = { ...pendingMessage.value, chat_id: payload.chat.id };
			sendMessage(msg);
			// Seteo todo lo pending en null, ya que ya no hay nada pendiente
			pendingPrivateChat.value = null;
			pendingMessage.value = null;
		}
	}

	function dispatch_change_username(payload) {
		if (payload.status === "success") {
			userInfo.value = {
				...userInfo.value,
				username: payload.data?.new_username,
			};
		} else {
			// TODO Notificar que salio mal
		}
	}

	function dispatch_change_name(payload) {
		if (payload.status === "success") {
			userInfo.value = { ...userInfo.value, name: payload.data?.new_name };
		} else {
			// TODO Notificar que salio mal
		}
	}

	function dispatch_change_nickname(payload) {
		if (payload.status === "success") {
			const contact_id = payload.data.contact_id;
			const new_nickname = payload.data.new_nickname;
			// Actualizamos los contactos
			contacts.value = contacts.value.map((c) => {
				if (c.id !== contact_id) return { ...c };

				return {
					id: c.id,
					username: c.username,
					name: c.name,
					avatar_url: c.avatar_url,
					last_seen_at: c.last_seen_at,
					contact_info: {
						...c.contact_info,
						nickname: new_nickname,
					},
				};
			});

			// Actualizamos el panel de la info de la persona
			if (openedPersonInfo.value?.id === contact_id) {
				openedPersonInfo.value = {
					...openedPersonInfo.value,
					contact_info: {
						...openedPersonInfo.value.contact_info,
						nickname: new_nickname,
					},
				};
			}

			const private_chat_id = Object.values(chatsInfo.value).find((chat) => {
				if (chat.type !== "private") return false;

				const otherMember = chat.members.find(
					(m) => m.user_id !== userInfo.value.id,
				);

				return otherMember?.user_id === contact_id;
			})?.id;

			console.log(`ID del private chat: ${private_chat_id}`);

			if (private_chat_id) {
				// Actualizamos el chatsInfo
				chatsInfo.value = {
					...chatsInfo.value,
					[private_chat_id]: {
						...chatsInfo.value[private_chat_id],
						name: new_nickname,
					},
				};

				// Actualizamos chats
				chats.value = chats.value.map((chat) =>
					chat.id === private_chat_id 
						? { ...chat, name: new_nickname } 
						: chat,
				);
			}

			//Actualizamos el sender_name en los grupales
			Object.entries(chatsInfo.value).forEach(([chatId, chat]) => {
				if (chat.type !== "group") return;

				// si no es miembro ni gastamos CPU
				const isMember = chat.members.some((m) => m.user_id === contact_id);
				if (!isMember) return;

				const updatedMessages = chat.messages.map(msg =>
					msg.user_id === contact_id
						? { ...msg, sender_name: new_nickname }
						: msg,
				);

				const updatedMembers = chat.members.map((m) =>
					m.user_id === contact_id
						? { ...m, nickname: new_nickname }
						: m,
				);

				chatsInfo.value = {
					...chatsInfo.value,
					[chatId]: {
						...chat,
						messages: updatedMessages,
						members: updatedMembers
					},
				};
			});
		} else {
			// TODO Notificar que salio mal
		}
	}

	function dispatch_group_created(payload) {
		// 1️⃣ Add chat to chat list
		if (payload.chat_item) {
			chats.value = [payload.chat_item, ...chats.value];
		}

		// 2️⃣ If full chat info is present (creator)
		if (payload.chat) {
			const chat = payload.chat;

			const normalizedMessages = chat.messages.map((m) => ({
				...m,
				front_msg_id: generateId(),
			}));

			chatsInfo.value = {
				...chatsInfo.value,
				[chat.id]: {
					...chat,
					messages: normalizedMessages,
				},
			};

			activeChatId.value = chat.id;
			sessionStorage.setItem("activeChatId", chat.id);
		}

		// 3️⃣ Reset group creation UI state
		creatingGroup.value = false;
		selectedGroupMembers.value = [];
		newGroupInfo.value = {
			name: "",
			description: "",
			avatar: null,
		};
	}

	function dispatch_contact_addition(payload) {
		if (payload.status !== "success") return;

		const newContact = payload.data.contact;
		const contact_id = newContact.id;
		const nickname = newContact.contact_info.nickname ?? newContact.name;

		// 1️⃣ contactos
		contacts.value = [newContact, ...contacts.value];

		// 2️⃣ panel abierto
		if (openedPersonInfo.value?.id === contact_id) {
			openedPersonInfo.value = {
				...openedPersonInfo.value,
				contact_info: newContact.contact_info,
			};
		}

		// 3️⃣ buscar private chat
		const private_chat_id = Object.values(chatsInfo.value).find((chat) => {
			if (chat.type !== "private") return false;

			const other = chat.members.find(
				m => m.user_id !== userInfo.value.id
			);

			return other?.user_id === contact_id;
		})?.id;

		if (!private_chat_id) return;

		// 4️⃣ actualizar chatsInfo (member + name)
		const chat = chatsInfo.value[private_chat_id];

		chatsInfo.value = {
			...chatsInfo.value,
			[private_chat_id]: {
				...chat,
				name: nickname,
				members: chat.members.map(m =>
					m.user_id === contact_id
						? { ...m, nickname }
						: m
				),
			},
		};

		// 5️⃣ actualizar chats list
		chats.value = chats.value.map(chat =>
			chat.id === private_chat_id
				? { ...chat, name: nickname }
				: chat
		);
	}


	function dispatch_contact_deletion(payload) {
		if (payload.status !== "success") return;

		const contact_id = payload.data.user_id;

		// 1️⃣ eliminar de contactos
		contacts.value = contacts.value.filter(
			c => c.id !== contact_id
		);

		// 2️⃣ limpiar panel
		if (openedPersonInfo.value?.id === contact_id) {
			const { contact_info, ...rest } = openedPersonInfo.value;
			openedPersonInfo.value = rest;
		}

		//Actualizamos el sender_name en los grupales
		Object.entries(chatsInfo.value).forEach(([chatId, chat]) => {
			if (chat.type !== "group") return;

			// si no es miembro ni gastamos CPU
			const member = chat.members.find((m) => m.user_id === contact_id);
			if (!member) return;

			const updatedMessages = chat.messages.map((msg) =>
				msg.user_id === contact_id
					? { ...msg, sender_name: member.name || member.username }
					: msg,
			);

			chatsInfo.value = {
				...chatsInfo.value,
				[chatId]: {
					...chat,
					messages: updatedMessages,
				},
			};
		})

		// 3️⃣ buscar private chat
		const private_chat_id = Object.values(chatsInfo.value).find((chat) => {
			if (chat.type !== "private") return false;

			const other = chat.members.find(
				m => m.user_id !== userInfo.value.id
			);

			return other?.user_id === contact_id;
		})?.id;

		if (!private_chat_id) return;

		const chat = chatsInfo.value[private_chat_id];

		const realName = chat.members.find(
			m => m.user_id === contact_id
		)?.name;

		// 4️⃣ actualizar chatsInfo
		chatsInfo.value = {
			...chatsInfo.value,
			[private_chat_id]: {
				...chat,
				name: realName,
				members: chat.members.map(m =>
					m.user_id === contact_id
						? { ...m, nickname: null }
						: m
				),
			},
		};

		// 5️⃣ actualizar chats list
		chats.value = chats.value.map(chat =>
			chat.id === private_chat_id
				? { ...chat, name: realName }
				: chat
		);
	}

	function dispatch_chat_member_removed({ chat_id, user_id }) {
		const chat = chatsInfo.value[chat_id];
		if (!chat) return;

		// Remove member reactively
		chatsInfo.value = {
			...chatsInfo.value,
			[chat_id]: {
				...chat,
				members: chat.members.filter((m) => m.user_id !== user_id),
			},
		};

		// If I was removed → kick me out
		if (user_id === userInfo.value.id) {
			activeChatId.value = null;

			// Remove chat reactively
			const { [chat_id]: _, ...rest } = chatsInfo.value;
			chatsInfo.value = rest;

			chats.value = chats.value.filter((c) => c.id !== chat_id);
		}
	}

	function dispatch_chat_member_added(payload) {
		const chat_id = payload.chat_id;
		const chat = chatsInfo.value[chat_id];
		if (!chat) return;

		// Replace members list reactively
		chatsInfo.value = {
			...chatsInfo.value,
			[chat_id]: {
				...chat,
				members: payload.members,
			},
		};
	}

	function dispatch_chat_admin_changed(payload) {
		const chat_id = payload.chat_id;
		const new_admin_id = payload.new_admin_id;

		const chat = chatsInfo.value[chat_id];
		if (!chat) return;

		// Update the members list reactively
		chatsInfo.value = {
			...chatsInfo.value,
			[chat_id]: {
			...chat,
			members: chat.members.map((m) =>
				m.user_id === new_admin_id ? { ...m, role: "admin" } : { ...m, role: "member" }
			),
			},
		};

		// Optionally, update the chat list if you show admin info there
		chats.value = chats.value.map((c) =>
			c.id === chat_id
			? {
				...c,
					members: chatsInfo.value[chat_id].members,
				}
			: c
		);
	}

	function dispatch_group_name_changed(payload) {
		if (payload.status === 'success') {
			chats.value = chats.value.map((c) =>
				c.id === payload.chat_id
				? {
					...c,
						name: payload.new_name
					}
				: c
			);
			const chat = chatsInfo.value[payload.chat_id]
			chatsInfo.value = {
				...chatsInfo.value,
				[payload.chat_id]: {
					...chat,
						name: payload.new_name
				},
			};
		}
	}
	
	function dispatch_group_description_changed(payload) {
		if (payload.status === 'success') {
			chats.value = chats.value.map((c) =>
				c.id === payload.chat_id
				? {
					...c,
						description: payload.new_description
					}
				: c
			);
			const chat = chatsInfo.value[payload.chat_id]
			chatsInfo.value = {
				...chatsInfo.value,
				[payload.chat_id]: {
					...chat,
						description: payload.new_description
				},
			};
		}
	}

	function dispatch_admin_given_to_member(payload) {
		const chat_id = payload.chat_id;
		const member = payload.member;

		const chat = chatsInfo.value[chat_id]
		console.log(`CHAT`)
		console.log(chat)

		const updatedMembers = chat.members.map((m) =>
			m.user_id === member.user_id
				? member
				: m,
		);

		chatsInfo.value = {
			...chatsInfo.value, 
			[chat_id]: {
				...chat,
					members: updatedMembers
			}
		}
	}

	function dispatch_group_avatar_updated(payload) {
		const chat_id = payload.chat_id;
		const avatar_url = payload.avatar_url;

		const chat = chatsInfo.value[chat_id];
		if (!chat) return;

		chatsInfo.value = {
			...chatsInfo.value,
			[chat_id]: {
				...chat,
				avatar_url: avatar_url
			}
		};

		chats.value = chats.value.map(chat => {
			if (chat.id === chat_id) {
				return { ...chat, avatar_url: avatar_url };
			}
			return chat;
		});
	}

	function disconnect() {
		if (socket.value) {
			send({ type: "logout" });
			socket.value.close();
		}
		socket.value = null;
		userInfo.value = null;
		chats.value = [];
		chatsInfo.value = {};
		activeChatId.value = null;
		contacts.value = [];
		contactsLoaded.value = false;
		openedPersonInfo.value = null;
		peopleSearchResults.value = null;
		pendingPrivateChat.value = null;
		pendingMessage.value = null;

		creatingGroup.value = false;
		selectedGroupMembers.value = [];
		newGroupInfo.value = {
			name: "",
			description: "",
			avatar: null,
		};

		themeStore.setTheme('dark');
		
		sessionStorage.clear();
	}

	function send(data) {
		if (socket.value?.readyState === WebSocket.OPEN) {
			socket.value.send(JSON.stringify(data));
		} else {
			console.error("El socket no está abierto");
		}
	}

	function openChat(chatId) {
		pendingPrivateChat.value = null;
		pendingMessage.value = null;

		activeChatId.value = chatId;
		sessionStorage.setItem("activeChatId", chatId);

		const hasCache = !!chatsInfo.value[chatId];

		console.log(`HasCache: ${hasCache}`);
		// Si no tenemos la info del chat se la pedimos al back
		if (!hasCache) {
			send({
				type: "open_chat",
				chat_id: chatId,
			});
		}

		// Si no le pedimos al back, tenemos que actualizar el ChatListItem
		if (hasCache) {
			const lastMsg = getLastMessage(chatsInfo.value[chatId]);

			if (lastMsg) updateChatListItem(lastMsg);
		}

		// Le decimos al back que leímos los mensajes del chat
		send({
			type: "chat_messages_read",
			chat_id: chatId,
		});
	}

	function sendMessage(front_msg) {
		const chat_id = front_msg.chat_id;
		const chat = chatsInfo.value[chat_id];

		if (chat) {
			chatsInfo.value = {
				...chatsInfo.value,
				[chat_id]: {
					...chat,
					messages: [...chat.messages, front_msg],
				},
			};
		}

		send({
			type: "send_message",
			msg: front_msg,
		});
	}

	function getLastMessage(chat) {
		return chat.messages.reduce((latest, m) => {
			if (!latest) return m;
			return new Date(m.time) > new Date(latest.time) ? m : latest;
		}, null);
	}

	function updateChatListItem(msg) {
		if (!msg) return;

		chats.value = chats.value.map((chat) =>
			chat.id === msg.chat_id
				? {
						...chat,
						unread_messages: 0,
						last_message: msg,
					}
				: chat,
		);
	}

	function setReadIncomingMessages(chatId) {
		const hasCache = !!chatsInfo.value[chatId];
		if (hasCache) {
			const chat = chatsInfo.value[chatId];

			chatsInfo.value = {
				...chatsInfo.value,
				[chatId]: {
					...chat,
					messages: chat.messages.map((m) =>
						m.type === "incoming" && m.state !== "read"
							? { ...m, state: "read" }
							: m,
					),
				},
			};
		}
	}

	function markMessagesDelivered(messageIds) {
		Object.keys(chatsInfo.value).forEach((chatId) => {
			const chat = chatsInfo.value[chatId];
			if (!chat) return;

			// Actualizamos los mensajes
			const messages = chat.messages.map((m) => {
				const msgId = m.id ?? m.front_msg_id;
				return messageIds.includes(msgId) && m.state === "sent"
					? { ...m, state: "delivered" }
					: m;
			});

			// Reemplazamos en chatsInfo
			chatsInfo.value = {
				...chatsInfo.value,
				[chatId]: { ...chat, messages },
			};

			// Actualizamos last_message si es uno de los que cambió
			const lastMsg = messages[messages.length - 1];
			if (lastMsg && messageIds.includes(lastMsg.id ?? lastMsg.front_msg_id)) {
				updateChatListItem(lastMsg);
			}
		});
	}

	function updateAvatar(avatarUrl) {
		if (!userInfo.value) return;

		userInfo.value = {
			...userInfo.value,
			avatar_url: avatarUrl,
		};
	}

	function updateGroupAvatar(avatarUrl) {
		if (!newGroupInfo.value) return;

		newGroupInfo.value = {
			...newGroupInfo.value,
			avatar: avatarUrl,
		};
	}

	function requestContactsIfNeeded() {
		if (contactsLoaded.value) return;
		console.log("Le pedimos los contactos al back");
		send({ type: "get_contacts" });
	}

	function getPersonInfo(personId) {
		console.log(`Se quiere pedir la info de la persona cuyo id es ${personId}`);
		send({
			type: "get_person_info",
			person_id: personId,
		});
	}

	function deletePersonInfo() {
		openedPersonInfo.value = null;
	}

	function deletePeopleSearchResults() {
		peopleSearchResults.value = null;
	}

	function searchPeople(input) {
		send({
			type: "search_people",
			input: input,
		});
	}

	function openPendingPrivateChat(personInfo) {
		console.log("Se abre un chat que no está creado en el back");
		pendingPrivateChat.value = personInfo.value;
		activeChatId.value = null;
		sessionStorage.removeItem("activeChatId");
	}

	function createPrivateChatAndSendMessage(front_pending_msg) {
		console.log(
			`Queremos crear un chat para mandar despues '${front_pending_msg.content}'`,
		);
		pendingMessage.value = front_pending_msg;

		send({
			type: "create_private_chat",
			user_id: pendingPrivateChat.value.id,
		});
		console.log(`Se hizo el send`);
	}

	function changeUsername(new_usr) {
		console.log(`Se llama a changeUSername con: ${new_usr}`);
		send({
			type: "change_username",
			new_username: new_usr,
		});
	}

	function changeName(new_name) {
		send({
			type: "change_name",
			new_name: new_name,
		});
	}

	function changeNickname(person_id, new_nickname) {
		send({
			type: "change_nickname",
			user_id: person_id,
			new_nickname: new_nickname,
		});
	}

	function addContact(person_id) {
		send({
			type: "add_contact",
			user_id: person_id,
		});
	}

	function deleteContact(person_id) {
		send({
			type: "delete_contact",
			user_id: person_id,
		});
	}

	function changeGroupName(chat_id, new_name) {
		send({
			type: "change_group_name",
			chat_id: chat_id,
			new_name: new_name
		});
	}

	function changeGroupDescription(chat_id, new_description) {
		send({
			type: "change_group_description",
			chat_id: chat_id,
			new_description: new_description
		});
	}

	function getOtherMemberId(chatInfo) {
		if (!chatInfo?.members) return null

		return chatInfo.members.find(
			m => String(m.user_id) !== String(userInfo.value.id)
		)?.user_id
	}

	function giveAdmin(chat_id, member_id) {
		send({
			type: "give_admin",
			chat_id: chat_id,
			user_id: member_id
		});
	}

	function addMembers(chat_id, member_ids) {
		send({
			type: "add_members",
			chat_id: chat_id,
			member_ids: member_ids
		});
	}

	function removeMember(chat_id, member_id) {
		send({
			type: "remove_member",
			chat_id: chat_id,
			member_id: member_id
		});
	}

	function changeGroupAvatar(chatId, avatarUrl) {
		if (!chatsInfo.value[chatId]) return

		chatsInfo.value[chatId].avatar_url = avatarUrl
	}

	return {
		socket,
		userInfo,
		chats,
		chatsInfo,
		activeChatId,
		contacts,
		openedPersonInfo,
		peopleSearchResults,
		pendingPrivateChat,
		pendingMessage,
		connect,
		disconnect,
		send,
		openChat,
		sendMessage,
		updateAvatar,
		requestContactsIfNeeded,
		getPersonInfo,
		deletePersonInfo,
		deletePeopleSearchResults,
		searchPeople,
		openPendingPrivateChat,
		createPrivateChatAndSendMessage,
		changeUsername,
		changeName,
		changeNickname,

		creatingGroup,
		selectedGroupMembers,
		newGroupInfo,
		updateGroupAvatar,
		addContact,
		deleteContact,
		changeGroupName,
		changeGroupDescription,

		getOtherMemberId,
		giveAdmin,
		addMembers,
		removeMember,
		changeGroupAvatar
	};
});
