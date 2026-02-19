<script setup>
import { ref, computed } from "vue";
import { useSocketStore } from "@/stores/socket";
import { storeToRefs } from "pinia";
import PeopleSearchBar from "@/components/people/PeopleSearchBar.vue";

/* -----------------------
 * Props & Emits
 * --------------------- */
const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
  existingMemberIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(["update:modelValue"]);

/* -----------------------
 * Store
 * --------------------- */
const socketStore = useSocketStore();
const { contacts, userInfo, peopleSearchResults } =
  storeToRefs(socketStore);

/* -----------------------
 * Local state
 * --------------------- */
const searchText = ref("");
const selectedPeopleMap = ref(new Map());

/* -----------------------
 * Methods
 * --------------------- */
function toggleMember(person) {
  let updated = [...props.modelValue];

  if (updated.includes(person.id)) {
    updated = updated.filter((id) => id !== person.id);
    selectedPeopleMap.value.delete(person.id);
  } else {
    updated.push(person.id);
    selectedPeopleMap.value.set(person.id, person);
  }

  emit("update:modelValue", updated);
}

function searchPeople(input) {
  searchText.value = input;

  if (input && input.trim()) {
    socketStore.searchPeople(input);
  } else {
    socketStore.deletePeopleSearchResults();
  }
}

function getDisplayName(person) {
  const contact = contacts.value.find((c) => c.id === person.id);
  if (contact) {
    return contact.contact_info?.nickname || person.name || null;
  }
  return person.name || null;
}

/* -----------------------
 * Computed
 * --------------------- */
const selectedPeople = computed(() =>
  Array.from(selectedPeopleMap.value.values())
);

const peopleToShow = computed(() => {
  const q = searchText.value?.trim();
  if (!q) return [];

  return (peopleSearchResults.value || []).filter(
    (p) =>
      p.id !== userInfo.value?.id &&
      !props.modelValue.includes(p.id) &&
      !props.existingMemberIds.includes(p.id)
  );
});

const unselectedContacts = computed(() =>
  contacts.value.filter(
    (p) =>
      !props.modelValue.includes(p.id) &&
      !props.existingMemberIds.includes(p.id)
  )
);
</script>

<template>
  <div class="selector">
    <PeopleSearchBar
      class="search-bar"
      @search-people="searchPeople"
    />

    <div class="contacts-list">
      <!-- SELECTED -->
      <template v-if="!searchText && selectedPeople.length">
        <p class="selected-label">Seleccionados</p>

        <label
          v-for="person in selectedPeople"
          :key="`selected-${person.id}`"
          class="contact-item selected"
        >
          <input
            type="checkbox"
            checked
            @change="toggleMember(person)"
          />

          <img :src="person.avatar_url" class="avatar" />
          <span class="main-name">
            {{ getDisplayName(person) }}
          </span>
          <span class="second-name">
            {{ `~${person.username}` }}
          </span>
        </label>
      </template>

      <!-- SEARCH RESULTS -->
      <label
        v-if="searchText"
        v-for="person in peopleToShow"
        :key="person.id"
        class="contact-item"
      >
        <input
          type="checkbox"
          :checked="modelValue.includes(person.id)"
          @change="toggleMember(person)"
        />

        <img :src="person.avatar_url" class="avatar" />
        <span class="main-name">
          {{ getDisplayName(person) }}
        </span>
        <span class="second-name">
          {{ `~${person.username}` }}
        </span>
      </label>

      <!-- CONTACTS -->
      <template v-else>
        <p
          v-if="unselectedContacts.length"
          class="selected-label"
        >
          Contactos
        </p>

        <label
          v-for="person in unselectedContacts"
          :key="person.id"
          class="contact-item"
        >
          <input
            type="checkbox"
            :checked="modelValue.includes(person.id)"
            @change="toggleMember(person)"
          />

          <img :src="person.avatar_url" class="avatar" />
          <span class="main-name">
            {{ getDisplayName(person) }}
          </span>
          <span class="second-name">
            {{ `~${person.username}` }}
          </span>
        </label>
      </template>
    </div>
  </div>
</template>

<style scoped>
.selector {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.search-bar {
  margin: 1rem;
}

.contacts-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 0 1rem 1rem;
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

.avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;
}

.main-name {
  font-size: 1.5rem;
  color: var(--text-main);
}

.second-name {
  font-size: 1.3rem;
  color: var(--text-muted);
}

.selected-label {
  margin: 6px 0 4px;
  font-size: 12px;
  font-weight: 600;
  color: var(--text-main);
  text-transform: uppercase;
}
</style>
