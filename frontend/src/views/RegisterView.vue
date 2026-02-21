<script setup>
import { ref, onMounted, computed } from "vue";
import { useRouter } from "vue-router";
import { useSocketStore } from "@/stores/socket";
import { useThemeStore } from "@/stores/theme";
import logoLight from "@/assets/logo/Echo_Logo_Completo.svg";
import logoDark from "@/assets/logo/Echo_Logo_Completo_Negativo.svg";

const API_URL = import.meta.env.VITE_API_URL

const themeStore = useThemeStore()
const theme = computed(() => themeStore.theme)

const username = ref("");
const password = ref("");
const name = ref("");
const email = ref("");
const avatarFile = ref(null);
const avatarPreview = ref(null);

const router = useRouter();
const socketStore = useSocketStore();
const errorMessage = ref(null)

function humanizeFieldError(field, msg) {
	switch (field) {
		case "username":
			if (msg === "can't be blank") return "Tenés que elegir un nombre de usuario"
			if (msg === "has already been taken") return "El nombre de usuario ya está en uso"
			if (msg === "can only contain letters, numbers, and underscores")
				return "El username solo puede usar letras, números y _"
			if (msg.includes("at least")) return "El username es demasiado corto"
			if (msg.includes("at most")) return "El username es demasiado largo"
			return "Username inválido"

		case "email":
			if (msg === "can't be blank") return "Tenés que ingresar un email"
			if (msg === "has already been taken") return "Ese email ya está registrado"
			if (msg === "has invalid format") return "El email no tiene un formato válido"
			return "Email inválido"

		case "password":
			if (msg === "can't be blank") return "Tenés que ingresar una contraseña"
			if (msg.includes("at least")) return "La contraseña debe tener al menos 8 caracteres"
			return "Contraseña inválida"

		case "name":
			if (msg === "can't be blank") return "Tenés que ingresar tu nombre"
			if (msg.includes("at most")) return "El nombre es demasiado largo"
			return "Nombre inválido"

		default:
			return "Dato inválido"
	}
}

function isValidEmail(value) {
	return /^[^\s]+@[^\s]+$/.test(value)
}

function handleBackendErrors(errors) {
	const msgs = []

	for (const field in errors) {
		msgs.push(
			humanizeFieldError(field, errors[field])
		)
	}
	errorMessage.value = msgs.map(m => `• ${m}`).join("\n")
}

async function handleRegister() {
	if (!isValidEmail(email.value)) {
		const fakeBackendError = {
			email: "has invalid format"
		}

		handleBackendErrors(fakeBackendError)
		return
	}

	try {
		const formData = new FormData();

		formData.append("username", username.value);
		formData.append("password", password.value);
		formData.append("name", name.value);
		formData.append("email", email.value);

		// only send avatar if user selected one
		if (avatarFile.value) {
			formData.append("avatar", avatarFile.value);
		}

		const res = await fetch(
			// "http://localhost:4000/api/register",
			`${API_URL}/api/register`,
			{
				method: "POST",
				body: formData, // multipart/form-data
			},
		);

		const data = await res.json();

		if (!res.ok) {

			if (data.errors) {
				handleBackendErrors(data.errors)
				return
			}
			if (data.error) {
				switch (data.error) {
					case "Invalid multipart data":
						errorMessage.value = "Error al enviar el formulario"
						break
					case "Invalid avatar type":
						errorMessage.value = "El avatar debe ser una imagen (jpg, png o webp)"
						break
					case "Invalid avatar":
						errorMessage.value = "Archivo de avatar inválido"
						break
					case "Avatar too large":
						errorMessage.value = "El avatar es demasiado pesado (máx 2MB)"
						break
					case "Avatar upload failed":
						errorMessage.value = "No se pudo subir el avatar"
						break
					default:
						errorMessage.value = "Datos inválidos"
				}
				return
			}
		}

		socketStore.disconnect();

		const token = data.token;
		sessionStorage.setItem("token", token);
		
		socketStore.connect(token);
		router.push("/chats");
	} catch (e) {
    errorMessage.value = "No se pudo conectar con el servidor"
  }

	onMounted(() => {
		themeStore.setTheme('dark')
	});
}

function onFileChange(e) {
	const file = e.target.files[0] || null;
	avatarFile.value = file;

	if (file) {
		avatarPreview.value = URL.createObjectURL(file);
	} else {
		avatarPreview.value = null;
	}
}
</script>

<template>
	<div class="body">
		<div class="register-container">
			<img
				:src="theme === 'dark' ? logoDark : logoLight"
				class="logo"
				alt="Echo logo"
			/>
			<p>Iniciar sesión</p>

			<form novalidate @submit.prevent="handleRegister">
				<input type="text" placeholder="Username" v-model="username" />

				<input type="text" placeholder="Nombre Completo" v-model="name" />

				<input type="text" placeholder="Correo electrónico" v-model="email" />

				<input type="password" placeholder="Contraseña" v-model="password" />

				<div v-if="avatarPreview" class="avatar-preview">
					<img :src="avatarPreview" alt="Avatar preview" />
				</div>
				<label class="file-upload">
					<input type="file" accept="image/*" @change="onFileChange" />
					<span>
						{{ avatarFile ? "Cambiar avatar" : "Elegir avatar" }}
					</span>
				</label>

				<p v-if="errorMessage" class="error-box">
					{{ errorMessage }}
				</p>

				<button type="submit">Registrar</button>
			</form>
		</div>
		<p>¿Ya tenés cuenta?</p>
		<router-link to="/login" class="login-link"> Iniciar Sesión </router-link>
	</div>
</template>

<style scoped>
.body {
	display: flex;
	flex-direction: column;
	justify-content: center;
	place-items: center;
	min-width: 320px;
	min-height: 100vh;
}
p {
	margin-bottom: 20px;
}
.logo {
	height: 12rem;
	padding: 0 0 4.5rem 0;
	will-change: filter;
	transition: filter 300ms;
}

.register-container {
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: center;
	color: white;
	margin-bottom: 4rem;
}

form {
	display: flex;
	flex-direction: column;
	gap: 12px;
	width: 280px;
}

input {
	padding: 10px;
	border-radius: 6px;
	border: none;
	background-color: var(--bg-chatlist-hover);
}

button {
	padding: 10px;
	border-radius: 6px;
	border: none;
	background: #2563eb;
	color: white;
	cursor: pointer;
}

.login-link {
	color: #93c5fd;
	cursor: pointer;
	text-decoration: none;
}
.login-link:hover {
	color: #6b8fb8;
}

.avatar-preview {
	width: 120px;
	height: 120px;
	border-radius: 50%;
	overflow: hidden;
	margin: 0 auto 12px auto;
	border: 2px solid #93c5fd;
	display: flex;
	align-items: center;
	justify-content: center;
	background: #1e293b;
}

.avatar-preview img {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

.file-upload {
	display: flex;
	justify-content: center;
}

.file-upload input {
	display: none;
}

.file-upload span {
	padding: 8px 16px;
	border-radius: 6px;
	background: #2563eb; /* same as register button */
	color: white;
	font-size: 14px;
	font-weight: 500;
	cursor: pointer;
	transition:
		background-color 0.2s ease,
		transform 0.1s ease;
}

.file-upload span:hover {
	background: #1d4ed8;
}

.file-upload span:active {
	transform: scale(0.97);
}

.error-box {
  background: #481818;
  box-shadow: 0 0 5px 5px rgb(125, 8, 8) inset;
  color: white;
  padding: 8px 10px;
  border-radius: 6px;
  font-size: 1.3rem;
  text-align: center;
  white-space: pre-line;
}

</style>
