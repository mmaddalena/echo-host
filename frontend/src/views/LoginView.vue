<script setup>
import { ref, computed, onMounted } from "vue";
import { useRouter } from "vue-router";
import { useSocketStore } from "@/stores/socket";
import logoLight from "@/assets/logo/Echo_Logo_Completo.svg";
import logoDark from "@/assets/logo/Echo_Logo_Completo_Negativo.svg";
import { useThemeStore } from "@/stores/theme";

const themeStore = useThemeStore()
const theme = computed(() => themeStore.theme)

const username = ref("lucas"); //TODO CAMBIAR A VACIO ("")
const password = ref("12345678"); //TODO CAMBIAR A VACIO ("")
const router = useRouter();
const socketStore = useSocketStore();
const errorMessage = ref(null)


async function handleLogin() {
	errorMessage.value = null

	try {
		const res = await fetch(
			"http://localhost:4000/api/login", 
			//"/api/login", 
			{
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({
				username: username.value,
				password: password.value,
			}),
		});

		const data = await res.json();

		if (!res.ok) {
      // traducimos mensajes del backend
      switch (data.error) {
        case "User not found":
          errorMessage.value = "El usuario no existe"
          break
        case "Invalid password":
          errorMessage.value = "Contraseña incorrecta"
          break
        default:
          errorMessage.value = "Credenciales inválidas"
      }
      return
    }

		const token = data.token;

		socketStore.disconnect();

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
</script>

<template>
	<div class="body">
		<div class="login-container">
			<img
				:src="theme === 'dark' ? logoDark : logoLight"
				class="logo"
				alt="Echo logo"
			/>
			<p>Iniciar sesión</p>

			<form @submit.prevent="handleLogin">
				<input type="text" placeholder="Username" v-model="username" />

				<input type="password" placeholder="Contraseña" v-model="password" />

				<p v-if="errorMessage" class="error-box">
					{{ errorMessage }}
				</p>

				<button type="submit">Entrar</button>
			</form>
		</div>
		<p>¿No tenés cuenta?</p>
		<router-link to="/register" class="register-link">
			Crear cuenta
		</router-link>
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

.login-container {
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

.register-link {
	color: #93c5fd;
	cursor: pointer;
	text-decoration: none;
}
.register-link:hover {
	color: #6b8fb8;
}

.error-box {
  background: #481818;
	box-shadow: 0 0 5px 5px rgb(125, 8, 8) inset;
  color: white;
  padding: 8px 10px;
  border-radius: 6px;
  font-size: 1.3rem;
  text-align: center;
}

</style>
