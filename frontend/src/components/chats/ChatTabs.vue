<script setup>
const emit = defineEmits(["change-to-tab"]);

const props = defineProps({
	activeTab: {
		type: String,
	},
});

function changeTab(toTab) {
	emit("change-to-tab", toTab);
}
</script>

<template>
	<div class="tabs">
		<button
			class="tab"
			:class="{ muted: activeTab !== 'all' }"
			@click="changeTab('all')"
		>
			Todos
		</button>
		<button
			class="tab"
			:class="{ muted: activeTab !== 'groups' }"
			@click="changeTab('groups')"
		>
			Grupos
		</button>
	</div>
</template>

<style scoped>
.tabs {
	background-color: none;
	display: flex;
	height: 4rem;
}
.tab {
	flex: 1;
	height: auto;
	background-color: var(--bg-peoplelist-panel);
	color: var(--text-main);
	font-weight: bold;
	cursor: pointer;
	border: none;
	border-radius: 1.5rem 1.5rem 0 0;
}
.muted {
	background-color: var(--bg-peoplelist-muted);
}
</style>
