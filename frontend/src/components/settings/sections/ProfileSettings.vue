<script setup>
import { ref, nextTick, computed, onMounted, watch } from "vue";
import { useSocketStore } from "@/stores/socket";
import IconEdit from "@/components/icons/IconEdit.vue";
import IconConfirm from "@/components/icons/IconConfirm.vue";

const socketStore = useSocketStore();

const uploading = ref(false);
const fileInput = ref(null);

const avatarUrl = computed(() => socketStore.userInfo?.avatar_url);

function triggerFilePicker() {
	fileInput.value.click();
}

async function onAvatarSelected(e) {
	const file = e.target.files[0];
	if (!file) return;

	if (file.size > 5_000_000) {
		alert("Max 5MB");
		return;
	}

	const formData = new FormData();
	formData.append("avatar", file);

	uploading.value = true;

	try {
		const res = await fetch(
			"http://localhost:4000/api/users/me/avatar",
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
		socketStore.updateAvatar(data.avatar_url);
	} catch (err) {
		console.error("Avatar upload failed", err);
	} finally {
		uploading.value = false;
	}
}

const editing = ref({
	username: false,
	name: false,
});

const username = ref("");
const name = ref("");

watch(
	() => socketStore.userInfo,
	(user) => {
		if (!user) return;
		username.value = user.username;
		name.value = user.name;
	},
	{ immediate: true },
);

const usernameInput = ref(null);
const nameInput = ref(null);

function handleEditMode(field) {
	editing.value[field] = true;
	if (field === "username") {
		editing.value["name"] = false;
		name.value = socketStore.userInfo.name;
		nextTick(() => {
			usernameInput.value.focus();
		});
	} else if (field === "name") {
		editing.value["username"] = false;
		username.value = socketStore.userInfo.username;
		nextTick(() => {
			nameInput.value.focus();
		});
	}
}

function handleConfirmEdit(field) {
	if (field === "username") {
		socketStore.changeUsername(username.value);
	} else if (field === "name") {
		socketStore.changeName(name.value);
	}
	editing.value["username"] = false;
	editing.value["name"] = false;
	//username.value = socketStore.userInfo.username
}

onMounted(() => {
	editing.value["username"] = false;
	editing.value["name"] = false;
});
</script>

<template>
	<section id="profile" class="settings-section">
		<h2>Perfil</h2>
		<div class="fields">
			<div class="field">
				<label>Nombre de Usuario</label>
				<div class="editable-field">
					<input
						ref="usernameInput"
						v-model="username"
						:type="editing.username ? 'text' : 'text'"
						:readonly="!editing.username"
					/>
					<Transition name="mini-swap" mode="out-in">
						<button
							v-if="!editing.username"
							class="edit-button"
							@click="handleEditMode('username')"
						>
							<IconEdit class="icon" />
						</button>
						<button
							v-else
							class="confirm-button"
							@click="handleConfirmEdit('username')"
						>
							<IconConfirm class="icon" />
						</button>
					</Transition>
				</div>
			</div>

			<div class="field">
				<label>Nombre</label>
				<div class="editable-field">
					<input
						ref="nameInput"
						v-model="name"
						type="text"
						:readonly="!editing.name"
					/>
					<Transition name="mini-swap" mode="out-in">
						<button
							v-if="!editing.name"
							class="edit-button"
							@click="handleEditMode('name')"
						>
							<IconEdit class="icon" />
						</button>
						<button
							v-else
							class="confirm-button"
							@click="handleConfirmEdit('name')"
						>
							<IconConfirm class="icon" />
						</button>
					</Transition>
				</div>
			</div>

			<!-- Avatar -->
			<div class="avatar-block">
				<img
					:src="avatarUrl || '/default-avatar.png'"
					class="avatar"
					alt="Avatar"
				/>

				<button @click="triggerFilePicker" :disabled="uploading">
					{{ uploading ? "Subiendo..." : "Cambiar avatar" }}
				</button>

				<input
					ref="fileInput"
					type="file"
					accept="image/*"
					hidden
					@change="onAvatarSelected"
				/>
			</div>
		</div>
	</section>
</template>

<style scoped>
.settings-section {
	padding: 2.4rem 0;
}

h2 {
	margin-bottom: 2rem;
	font-size: 2.2rem;
}

.fields {
	display: flex;
	flex-direction: column;
	gap: 1.6rem;
}

.field {
	display: flex;
	flex-direction: column;
	gap: 0.6rem;
}

label {
	font-size: 1.4rem;
	color: var(--text-muted);
	font-weight: bold;
}

.editable-field {
	display: flex;
	gap: 1rem;
}

input {
	background: none;
	border: 1px solid #2f3e63;
	border-radius: 0.8rem;
	padding: 0.8rem;
	color: var(--text-main);
	width: 22rem;
	font-size: 1.6rem;
}
input[readonly] {
	border: none;
	padding-left: 0;
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
	background-color: var(--main-app-color-2);
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
	display: flex;
	align-items: center;
	justify-content: center;
}
.icon {
	max-height: 2.2rem;
	max-width: 2.2rem;
	color: var(--text-main-light);
	padding: 0.1rem;
}

.mini-swap-enter-active,
.mini-swap-leave-active {
	transition:
		opacity 0.15s ease,
		transform 0.15s ease;
}
.mini-swap-enter-from {
	opacity: 0;
	transform: scale(0.85);
}
.mini-swap-leave-to {
	opacity: 0;
	transform: scale(0.85);
}

.avatar-block {
	display: flex;
	align-items: center;
	gap: 1.6rem;
	margin-top: 2rem;
}

.avatar {
	width: 72px;
	height: 72px;
	border-radius: 50%;
	object-fit: cover;
	border: 2px solid var(--avatar-border);
}

.avatar-block button {
	padding: 0.6rem 1.2rem;
	border-radius: 0.8rem;
	border: none;
	background: var(--main-app-color-2);
	cursor: pointer;
}

.avatar-block button:disabled {
	opacity: 0.6;
	cursor: not-allowed;
}
</style>
