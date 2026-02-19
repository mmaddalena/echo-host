<script setup>
import { ref, computed, watch } from "vue";
import { useSocketStore } from "@/stores/socket";
import { storeToRefs } from "pinia";

import GroupMemberSelector from "@/components/groups/GroupMemberSelector.vue";
import IconClose from '@/components/icons/IconClose.vue';
import IconImage from '@/components/icons/IconImage.vue';

const emit = defineEmits(["close"]);

const socketStore = useSocketStore();
/* -----------------------
 * Step control
 * --------------------- */
const step = ref(1); // 1: select members, 2: group info

/* -----------------------
 * Local state
 * --------------------- */
const selectedIds = ref([]);
const name = ref("");
const description = ref("");
const avatarFile = ref(null);
const avatarPreview = ref(null);

/* -----------------------
 * Computed
 * --------------------- */

const canGoNext = computed(() => selectedIds.value.length >= 1);
const canCreate = computed(() => name.value.trim().length > 0);

/* -----------------------
 * Methods
 * --------------------- */
function onAvatarChange(e) {
	const file = e.target.files[0];
	if (!file) return;

	avatarFile.value = file;
	avatarPreview.value = URL.createObjectURL(file);
}

function nextStep() {
	if (!canGoNext.value) return;
	step.value = 2;
}

function prevStep() {
	step.value = 1;
}

async function createGroup() {
	if (!canCreate.value) return;

	let avatarUrl = null;

	try {
		if (avatarFile.value) {
			// temporary UUID so we can upload before group exists
			const tempGroupId = crypto.randomUUID();
			avatarUrl = await uploadGroupAvatar(tempGroupId, avatarFile.value);
		}

		socketStore.send({
			type: "create_group",
			name: name.value.trim(),
			description: description.value.trim(),
			avatar_url: avatarUrl,
			member_ids: selectedIds.value,
		});

		close();
	} catch (e) {
		console.error("Error creating group:", e);
	}
}

function close() {
	reset();
	emit("close");
}

function reset() {
	step.value = 1;
	selectedIds.value = [];
	name.value = "";
	description.value = "";
	avatarFile.value = null;
	avatarPreview.value = null;
}

async function uploadGroupAvatar(groupId, file) {
	const formData = new FormData();
	formData.append("avatar", file);

	try {
		const res = await fetch(
			`http://localhost:4000/api/groups/${groupId}/avatar`,
			//"/api/users/me/avatar",
			{
				method: "POST",
				headers: {
					Authorization: `Bearer ${sessionStorage.getItem("token")}`,
				},
				body: formData,
			},
		);

		const data = await res.json();

		// update avatar in store
		socketStore.updateGroupAvatar(data.avatar_url);
		return data.avatar_url;
	} catch (err) {
		console.error("Avatar upload failed", err);
	}
}
</script>

<template>
	<div class="all"> 
		<div class="panel-header">
			<h3 v-if="step === 1">Nuevo grupo</h3>
			<h3 v-else>Información del grupo</h3>

			<button class="close-btn" @click="close">
				<IconClose class="close-icon"/>
			</button>
		</div>

		<!-- STEP 1: SELECT MEMBERS -->
		<div v-if="step === 1" class="panel-body">
			<p class="subtitle">Selecciona al menos 1 miembro</p>
			<GroupMemberSelector v-model="selectedIds" />
		</div>

		<!-- STEP 2: GROUP INFO -->
		<div v-else class="panel-body">
			<div class="avatar-section">
				<img 
					v-if="avatarPreview" 
					:src="avatarPreview" 
					class="group-avatar" 
				/>
				<div v-else class="group-avatar placeholder">
					<IconImage class="group-avatar-icon"/>
				</div>

				<label class="file-picker">
				<input
					type="file"
					accept="image/*"
					@change="onAvatarChange"
					hidden
				/>
				<span class="file-btn">Elegir imagen</span>
				<span class="file-name">
					{{ avatarFile ? avatarFile.name : "Ningún archivo seleccionado" }}
				</span>
			</label>

			</div>

			<input v-model="name" type="text" placeholder="Nombre del grupo" class="input" />

			<textarea
				v-model="description"
				placeholder="Descripción (opcional)"
				class="textarea"
			/>
		</div>

		<!-- Footer -->
		<div class="panel-footer">
			<button v-if="step === 2" @click="prevStep">Atrás</button>

			<button v-if="step === 1" :disabled="!canGoNext" @click="nextStep" class="next-btn">
				Siguiente
			</button>

			<button v-if="step === 2" :disabled="!canCreate" @click="createGroup">
				Crear grupo
			</button>
		</div>
	</div>
</template>

<style scoped>
.all {
	background: var(--bg-peoplelist-panel);
	border-radius: 1.5rem 1.5rem 0 0;

	display: flex;
	flex-direction: column;
	
	min-height: 0;
	overflow: hidden;
	flex: 1;
}
/* ---------- HEADER ---------- */
.panel-header {
	padding: 14px 18px;
	display: flex;
	justify-content: space-between;
	align-items: center;
	border-bottom: 1px solid rgba(255, 255, 255, 0.06);
	position: relative;
}
.panel-header h3 {
	font-size: 16px;
	font-weight: 600;
	margin: 0;
}
.close-btn {
	display: flex;
  justify-content: center;
  align-items: center;
  background-color: var(--bg-main);
  height: 3rem;
  width: 3rem;
  border-radius: 50%;
  border: none;

  position: absolute;
  top: 1rem;
  right: 1rem;
  cursor: pointer;

  font-size: 2rem;
  color: var(--text-main);
	padding: 0.8rem;
}
.close-btn:hover {
	color: #fff;
}

.search-bar {
	flex: 0 0 auto;
	margin: 2rem 3rem 1rem 3rem;
}

/* ---------- BODY ---------- */
.panel-body {
	flex: 1 1 auto;
	min-height: 0;
	padding: 16px 18px;
	overflow-y: auto;
	min-width: 0;
	overflow-x: hidden;
	scrollbar-gutter: stable;
}

.subtitle {
	font-size: 13px;
	color: var(--text-main);
	margin-bottom: 10px;
}

/* ---------- CONTACT LIST ---------- */
.main-name {
	font-size: 1.6rem !important;
	color: var(--text-main);
}
.second-name {
	font-size: 1.4rem;
	color: var(--text-muted);
}

.contacts-list {
	display: flex;
	flex-direction: column;
	gap: 6px;
}

.contact-item {
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 8px 10px;
	border-radius: 10px;
	cursor: pointer;
	transition: background 0.15s ease;
}

.contact-item:hover {
	background: var(--bg-peoplelist-hover);
}

.contact-item.selected {
	background: var(--bg-peoplelist-hover);
}

.contact-item input[type="checkbox"] {
	appearance: none;
	-webkit-appearance: none;
	background-color: var(--text-muted);
	border-radius: 0.5rem;
	width: 1.6rem;
	height: 1.6rem;
	cursor: pointer;
	filter: brightness(0.85);
}

.contact-item input[type="checkbox"]:checked {
	background-color: var(--main-app-color-2);
}
.contact-item input[type="checkbox"]::after {
	content: "";
	width: 0.6rem;
	height: 0.3rem;
	border-left: 2px solid var(--text-main-light);
	border-bottom: 2px solid var(--text-main-light);
	transform: rotate(-45deg) scale(0);
	display: block;
	margin: 0.4rem auto 0;
	transition: transform 0.12s ease;
}
.contact-item input[type="checkbox"]:checked::after {
	transform: rotate(-45deg) scale(1);
}


/* hover sutil */
.contact-item input[type="checkbox"]:hover {
	filter: brightness(1);
}

.avatar {
	width: 36px;
	height: 36px;
	border-radius: 50%;
	object-fit: cover;
}

.contact-item span {
	font-size: 14px;
	font-weight: 500;
}

/* ---------- AVATAR PICKER ---------- */
.avatar-section {
	display: flex;
	align-items: center;
	gap: 14px;
	margin-bottom: 14px;
}

.group-avatar {
	width: 6.4rem;
	height: 6.4rem;
	border-radius: 50%;
	object-fit: cover;
	background: var(--bg-chatlist-hover);
}
.group-avatar-icon {
	height: 3rem;
}

.placeholder {
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 26px;
	color: var(--text-muted);
}

.avatar-section input[type="file"] {
	font-size: 12px;
	color: var(--bg-chatlist-hover);
}


/* ---------- INPUTS ---------- */
.input,
.textarea {
	width: 100%;
	padding: 10px 12px;
	margin-top: 10px;
	border-radius: 10px;
	border: none;
	background: var(--bg-chatlist-hover);
	color: var(--text-main);
	font-size: 14px;
	font-family: inherit;
}

.input::placeholder,
.textarea::placeholder {
	color: var(--text-muted);
}

.textarea {
	resize: none;
	min-height: 80px;
}

.file-picker {
	display: flex;
	align-items: center;
	gap: 12px;
	cursor: pointer;
}

.file-btn {
	background: var(--main-app-color-2);
	color: var(--text-main-light);
	padding: 6px 14px;
	border-radius: 999px;
	font-size: 13px;
	font-weight: 500;
	transition: opacity .15s ease, transform .05s ease;
	white-space: nowrap;
}

.file-btn:hover {
	opacity: .9;
}

.file-btn:active {
	transform: scale(.97);
}

.file-name {
	font-size: 12px;
	color: var(--text-muted);
	overflow: hidden;
	text-overflow: ellipsis;
	max-width: 160px;
}


/* ---------- FOOTER ---------- */
.panel-footer {
	padding: 12px 18px;
	display: flex;
	justify-content: space-between;
	align-items: center;
	border-top: 1px solid rgba(255, 255, 255, 0.06);
}
.next-btn {
	margin-left: auto;
}

/* ---------- BUTTONS ---------- */
button {
	border: none;
	border-radius: 20px;
	padding: 6px 16px;
	font-size: 14px;
	font-weight: 500;
	cursor: pointer;
	transition:
		opacity 0.15s ease,
		transform 0.05s ease;
}

button:active {
	transform: scale(0.97);
}

button:disabled {
	opacity: 0.4;
	cursor: not-allowed;
}

.panel-footer button {
	background: var(--main-app-color-2);
	color: white;
}

.panel-footer button:first-child {
	/* background: transparent; */
	color: white;
}

.panel-footer button:first-child:hover {
	color: white;
}

.search {
	margin: 0;
	padding: 0.5rem 1rem;
	width: 100%;
	box-sizing: border-box;
}

.selected-label {
	margin: 6px 0 4px;
	font-size: 12px;
	font-weight: 600;
	color: var(--text-main);
	text-transform: uppercase;
}



.panel-body::-webkit-scrollbar {
  width: 0.8rem;
}

.panel-body::-webkit-scrollbar-track {
  background: transparent; /* rail invisible */
}

.panel-body::-webkit-scrollbar-thumb {
  background: var(--scroll-bar);
  border-radius: 999px;
}

.panel-body::-webkit-scrollbar-thumb:hover {
  background: var(--scroll-bar-hover);
}

.panel-body::-webkit-scrollbar-button {
  display: none; /* saca las flechitas */
}

</style>
