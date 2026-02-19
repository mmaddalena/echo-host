<script setup>
import { ref, watch } from "vue";

const {message, chatType} = defineProps({
	message: Object,
	chatType: String,
});

function formatHM(isoString) {
	return new Date(isoString).toLocaleTimeString("es-AR", {
		hour: "2-digit",
		minute: "2-digit",
	});
}

import IconMessageState from "../icons/IconMessageState.vue";
import IconFile from "../icons/IconFile.vue";

const zoomedImage = ref(null);

function openImage(src) {
	zoomedImage.value = src;
}

function closeImage() {
	zoomedImage.value = null;
}


watch(
	() => message,
	(msg) => {
		console.log(`cambio el msg: ${msg}`)
	}
)
</script>

<template>
	<div class="all" 
		:class="{ first: message?.isFirst }"
		:data-msg-id="message.id"
	>
		<img
			v-if="
				chatType == 'group' && message.type == 'incoming' && message?.isFirst
			"
			:src="message.avatar_url"
			class="avatar content image clickable"
			loading="lazy"
			@click="openImage(message.avatar_url)"
			alt="User Avatar"
		/>
		<div
			class="message"
			:class="[
				message.type,
				{
					'with-avatar-offset':
						chatType == 'private' || (chatType == 'group' && !message.isFirst)
				},
			]"
		>
			<div
				v-if="
					chatType == 'group' && message.type == 'incoming' && message?.isFirst
				"
				class="message-header"
			>
				<span class="user-name">{{ message.sender_name }}</span>
			</div>
			<div class="message-body">
				<!-- TEXT -->
				<span v-if="message.format === 'text'" class="content">
					{{ message.content }}
				</span>

				<!-- IMAGE -->
				<img
					v-else-if="message.format === 'image'"
					:src="message.content"
					class="content image msg-image clickable"
					loading="lazy"
					@click="openImage(message.content)"
				/>

				<!-- FILE -->
				<a
					v-else-if="message.format === 'file'"
					:href="message.content"
					target="_blank"
					class="content file"
				>
					<IconFile class="file-icon"/>	
				 {{ message.filename }}
				</a>

				<span class="meta">
					<Transition name="msg-state" mode="out-in">
						<IconMessageState
							v-if="message.type == 'outgoing'"
							:key="message.state"
							class="state-icon"
							:state="message.state"
						/>
					</Transition>
					<span class="time">
						{{ message.time ? formatHM(message.time) : message.time_zoned }}
					</span>
				</span>
			</div>
		</div>
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
.all {
	display: flex;
	gap: 1rem;
}
.first {
	margin-top: 1rem;
}
.message {
	display: flex;
	flex-direction: column;
	gap: 0.6rem;
	min-height: 3rem;
	max-width: 65%;
	padding: 0.6rem 1rem 0.3rem 1.4rem;
	border-radius: 15px;
}
.with-avatar-offset {
	margin-left: calc(3rem + 1rem);
}
.outgoing {
	background: var(--msg-out);
	margin-left: auto;
	margin-right: calc(3rem + 1rem);
}
.incoming {
	background: var(--msg-in);
	margin-right: auto;
}

.message-header {
	display: flex;
	gap: 1rem;
	align-items: center;

	opacity: 0.8;
}
.avatar {
	height: 3rem;
	width: 3rem;
	border-radius: 50%;
	background-color: none;
}
.user-name {
	font-size: 1.28rem;
	color: var(--text-main);
}

.message-body {
	display: inline-flex;
	align-items: flex-end;
	gap: 0.8rem;
}
.content {
	white-space: pre-wrap;
	word-break: break-word;
	padding-bottom: 0.3rem;
	text-align: left;
	font-size: 1.4rem;
	line-height: 1.4;
	color: var(--text-main);
}
.meta {
	display: inline-flex;
	align-items: flex-end;
	gap: 0.3rem;
	white-space: nowrap;
	margin-bottom: -0.2rem;
}
.state-icon {
	height: 1.8rem;
	color: var(--text-main);
	opacity: 0.6;
}
.time {
	font-size: 1.1rem;
	opacity: 0.6;
	flex-shrink: 0;
	color: var(--text-main);
}

.msg-state-enter-active,
.msg-state-leave-active {
	transition:
		opacity 0.25s ease,
		transform 0.25s ease;
}

.msg-state-enter-from,
.msg-state-leave-to {
	opacity: 0;
	transform: scale(0.85);
}

.image {
	max-width: 100%;
	max-height: 18rem;
	border-radius: 0.8rem;
	object-fit: cover;
}
.image.avatar {
	border-radius: 50%;
}
.msg-image {
	margin: 0.2rem -8rem 1.8rem -0.2rem;
}

.file {
	color: inherit;
	text-decoration: none;
	font-weight: 500;
	display: inline-flex;
	align-items: center;
	gap: 0.4rem;
}

.clickable {
	cursor: pointer;
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

.file-icon {
	height: 2.5rem;
	margin: 0 0 0 -0.2rem;
	fill: none;
	stroke-width: 0.15rem;
	stroke: var(--text-main);
}


.all.focused {
	background: var(--msg-focused);
	border-radius: 0.6rem;
	transition: background 0.3s;
}

.all-anchor.highlight {
	animation: pulse 1.2s ease;
}

.all {
	transition: background 0.6s ease;
}
</style>
