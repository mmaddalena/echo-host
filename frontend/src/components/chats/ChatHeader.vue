<script setup>
import IconSearch from "../icons/IconSearch.vue";
import IconOptsMenu from "../icons/IconOptsMenu.vue";
import { computed, ref, watch } from "vue";
import { formatAddedTime } from "@/utils/formatAddedTime";



const emit = defineEmits(["scroll-to-message", "open-chat-info"]);

const props = defineProps({
	chatInfo: {
		type: Object,
		default: null,
	},
	last_seen_at: { type: String, default: null },
	currentUserId: { type: [String, Number], default: null },
});

const zoomedImage = ref(null);

function openImage(src) {
	zoomedImage.value = src;
}

function closeImage() {
	zoomedImage.value = null;
}

const showSearch = ref(false);
const query = ref("");
const results = ref([]); // [{ id, content }]
const index = ref(0);
const loading = ref(false);

async function search() {
	if (!query.value || !props.chatInfo?.id) return;

	loading.value = true;

	try {
		const token = sessionStorage.getItem("token");

		const res = await fetch(
			`/api/chats/${props.chatInfo.id}/search?q=${encodeURIComponent(
				query.value,
			)}`,
			{
				headers: {
					Authorization: `Bearer ${token}`,
				},
			},
		);

		if (!res.ok) throw new Error("Search failed");

		results.value = await res.json();
		index.value = 0;

		jump();
	} catch (err) {
		console.error(err);
		results.value = [];
	} finally {
		loading.value = false;
	}
}

function jump() {
	const msg = results.value[index.value];
	if (msg) emit("scroll-to-message", msg.id);
}

function next() {
	if (index.value < results.value.length - 1) {
		index.value++;
	} else {
		index.value = 0;
	}
	jump();
}

function prev() {
	if (index.value > 0) {
		index.value--;
	} else {
		index.value = results.value.length - 1;
	}
	jump();
}

/* Reset search when chat changes */
watch(
	() => props.chatInfo?.id,
	() => {
		showSearch.value = false;
		query.value = "";
		results.value = [];
		index.value = 0;
	},
);


const membersStr = computed(() => {
	return (
		props.chatInfo?.members
			?.map(m => {
				console.log(`Id propio: ${props.currentUserId}`);
				console.log(`Id del miembro: ${m.user_id}`);
				
				return String(m.user_id) === String(props.currentUserId)
				? 'Tú'
				: m.nickname || m.name || `~${m.username}`
			})
			.join(", ")
	) ?? "";
});


function toggleSearch(){
	showSearch.value = !showSearch.value;
	query.value = "";
}

function openChatInfo() {
	props.chatInfo.last_seen_at = props.last_seen_at;
	emit("open-chat-info", props.chatInfo);
}
</script>

<template>
	<header v-if="chatInfo" class="chat-header" :class="{'no-border': showSearch}">
		<div class="user_info" @click="openChatInfo">
			<img
				:src="chatInfo.avatar_url"
				class="avatar content image clickable"
				loading="lazy"
				@click="openImage(chatInfo.avatar_url)"
			/>
			<div class="texts">
				<p class="name">{{ chatInfo.name }}</p>
				<span class="status">
					<p v-if="chatInfo.type == 'private'">
						{{ chatInfo.status }}
						<span v-if="chatInfo.status == 'Offline' && last_seen_at">
							- Ultima vez activo
							{{ formatAddedTime(last_seen_at) }}
						</span>
					</p>
					<p v-else>{{ membersStr }}</p>
				</span>
			</div>
		</div>
		<div class="opts_icons">
			<IconSearch class="icon" @click="toggleSearch" />
		</div>
	</header>

	<div v-if="showSearch" class="search-bar">
		<input v-model="query" placeholder="Search in chat" @keyup.enter="search" />

		<template v-if="results.length" class="search-results">
			<button @click="prev" class="search-move-btn">
				↑
			</button>
			<span class="search-amount-results">
				{{ index + 1 }} / {{ results.length }}
			</span>
			<button @click="next" class="search-move-btn">
				↓
			</button>
		</template>

		<span v-if="loading">Searching…</span>
	</div>

	<Teleport to="body">
		<Transition name="zoom">
			<div v-if="zoomedImage" class="image-overlay" @click.self="closeImage">
				<img :src="zoomedImage" class="zoomed-image" />
			</div>
		</Transition>
	</Teleport>
</template>

<style scoped>
.chat-header {
	background-color: var(--bg-chat-header);
	height: 7rem;
	padding: 1.5rem 4rem 1.5rem 1.6rem;
	display: flex;
	box-sizing: content-box;
	align-items: center;
	justify-content: space-between;
	border-bottom: 0.3rem solid rgba(255, 255, 255, 0.05);
}
.no-border {
	border-bottom: none;
}
.user_info {
	display: flex;
	gap: 2rem;
	align-items: center;
	cursor: pointer;
	flex: 1;
	margin-right: 2rem;
}
.avatar {
	height: 5rem;
	width: 5rem;
	border-radius: 50%;
}
.name {
	color: var(--text-main);
	font-size: 2.2rem;
	font-weight: bold;
}
.status {
	font-size: 1.5rem;
	color: var(--text-muted);
}
.opts_icons {
	display: flex;
	gap: 2rem;
}
.icon {
	height: 2.5rem;
	color: var(--text-main);
	fill: var(--text-main);
	cursor: pointer;
	padding: 0 1rem;
}

.clickable {
	cursor: zoom-in;
}

/* Overlay */
.image-overlay {
	position: fixed;
	inset: 0;
	background: rgba(0, 0, 0, 0.85);
	display: flex;
	align-items: center;
	justify-content: center;
	z-index: 9999;
	backdrop-filter: blur(4px);
}

/* Zoomed image */
.zoomed-image {
	max-width: 90vw;
	max-height: 90vh;
	border-radius: 1rem;
	object-fit: contain;
	cursor: zoom-out;
}

/* Animation */
.zoom-enter-active,
.zoom-leave-active {
	transition: opacity 0.25s ease;
}
.zoom-enter-from,
.zoom-leave-to {
	opacity: 0;
}

.search-bar {
	display: flex;
	gap: 0.5rem;
	padding: 0.6rem 1rem;
	background: var(--bg-chat-header);
	border-bottom: 0.3rem solid rgba(255, 255, 255, 0.05);
}

.search-bar input {
	all: unset;
	flex: 1;
	padding: 0.4rem 2rem;
	border-radius: 2rem;
	border: none;
	background-color: var(--bg-chatlist-hover);
}

.search-amount-results {
	font-size: 1.6rem;
	align-self: center;
}
.search-move-btn {
	all: unset;
	height: 3rem;
	width: 3rem;
	border-radius: 50%;
	background-color: var(--msg-in);

	display: flex;
	align-items: center;
	justify-content: center;
}
.search-move-btn:hover {
	background-color: var(--accent);
}
</style>
