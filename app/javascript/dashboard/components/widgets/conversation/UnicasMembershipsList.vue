<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useFunctionGetter } from 'dashboard/composables/store';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import UnicasAPI from '../../../api/integrations/unicas';

const props = defineProps({
  contactId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();

const contact = useFunctionGetter(
  'contacts/getContact',
  computed(() => props.contactId)
);

const hasPhone = computed(() => !!contact.value?.phone_number);

const user = ref(null);
const memberships = ref([]);
const loading = ref(true);
const error = ref('');

const profileRows = computed(() => {
  if (!user.value) return [];

  const documentValue = [user.value.document_type, user.value.document_number]
    .filter(Boolean)
    .join(' ');

  const rows = [
    {
      key: 'name',
      label: t('CONVERSATION_SIDEBAR.UNICAS.FIELDS.NAME'),
      value: user.value.full_name || user.value.name,
    },
    {
      key: 'roles',
      label: t('CONVERSATION_SIDEBAR.UNICAS.FIELDS.ROLES'),
      value: (user.value.roles || []).join(', '),
    },
    {
      key: 'email',
      label: t('CONVERSATION_SIDEBAR.UNICAS.FIELDS.EMAIL'),
      value: user.value.email,
    },
    {
      key: 'phone',
      label: t('CONVERSATION_SIDEBAR.UNICAS.FIELDS.PHONE'),
      value: user.value.phone,
    },
    {
      key: 'document',
      label: t('CONVERSATION_SIDEBAR.UNICAS.FIELDS.DOCUMENT'),
      value: documentValue,
    },
    {
      key: 'gender',
      label: t('CONVERSATION_SIDEBAR.UNICAS.FIELDS.GENDER'),
      value: user.value.gender,
    },
    {
      key: 'birthdate',
      label: t('CONVERSATION_SIDEBAR.UNICAS.FIELDS.BIRTHDATE'),
      value: user.value.birthdate,
    },
    {
      key: 'active',
      label: t('CONVERSATION_SIDEBAR.UNICAS.FIELDS.ACTIVE'),
      value:
        user.value.is_active === false
          ? t('CONVERSATION_SIDEBAR.UNICAS.NO')
          : t('CONVERSATION_SIDEBAR.UNICAS.YES'),
    },
    {
      key: 'last_login',
      label: t('CONVERSATION_SIDEBAR.UNICAS.FIELDS.LAST_LOGIN'),
      value: user.value.last_login_at,
    },
  ];

  return rows.filter(row => row.value);
});

const fetchMemberships = async () => {
  if (!hasPhone.value) {
    user.value = null;
    memberships.value = [];
    loading.value = false;
    error.value = '';
    return;
  }

  try {
    loading.value = true;
    error.value = '';
    const response = await UnicasAPI.getMemberships(props.contactId);
    user.value = response.data.user || null;
    memberships.value = response.data.memberships || [];
  } catch {
    error.value = 'CONVERSATION_SIDEBAR.UNICAS.ERROR';
    user.value = null;
    memberships.value = [];
  } finally {
    loading.value = false;
  }
};

watch(
  () => [props.contactId, contact.value?.phone_number],
  () => {
    fetchMemberships();
  },
  { immediate: true }
);
</script>

<template>
  <div class="px-4 py-2 text-n-slate-12">
    <div v-if="!hasPhone" class="text-center text-n-slate-12">
      {{ $t('CONVERSATION_SIDEBAR.UNICAS.NO_PHONE') }}
    </div>
    <div v-else-if="loading" class="flex justify-center items-center p-4">
      <Spinner size="32" class="text-n-brand" />
    </div>
    <div v-else-if="error" class="text-center text-n-ruby-12">
      {{ $t('CONVERSATION_SIDEBAR.UNICAS.ERROR') }}
    </div>
    <div v-else-if="!user" class="text-center text-n-slate-12">
      {{ $t('CONVERSATION_SIDEBAR.UNICAS.EMPTY') }}
    </div>
    <div v-else class="flex flex-col gap-3">
      <div class="flex flex-col gap-2">
        <div
          v-for="row in profileRows"
          :key="row.key"
          class="flex justify-between gap-3 text-sm"
        >
          <span class="text-n-slate-11 shrink-0">{{ row.label }}</span>
          <span class="text-n-slate-12 text-right truncate">{{
            row.value
          }}</span>
        </div>
      </div>
      <div v-if="memberships.length">
        <div class="text-sm font-medium text-n-slate-12 py-1">
          {{ $t('CONVERSATION_SIDEBAR.UNICAS.MONEY_POOLS') }}
        </div>
        <div
          v-for="membership in memberships"
          :key="membership.money_pool_id"
          class="py-3 border-b border-n-weak last:border-b-0 flex flex-col gap-1"
        >
          <div class="flex justify-between items-center gap-2">
            <span class="font-medium text-n-slate-12 truncate">
              {{ membership.name }}
            </span>
            <span
              class="text-xs px-2 py-1 rounded bg-n-solid-3 text-n-slate-12 capitalize truncate"
            >
              {{ membership.status }}
            </span>
          </div>
          <div class="text-sm text-n-slate-11">
            {{ membership.role_label }}
          </div>
          <div
            v-if="membership.member_name || membership.document_number"
            class="text-sm text-n-slate-11"
          >
            <span v-if="membership.member_name">{{
              membership.member_name
            }}</span>
            <span v-if="membership.document_number" class="pl-2">
              {{
                $t('CONVERSATION_SIDEBAR.UNICAS.DOCUMENT', {
                  number: membership.document_number,
                })
              }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
