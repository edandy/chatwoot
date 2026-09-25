/* global axios */

import ApiClient from '../ApiClient';

class UnicasAPI extends ApiClient {
  constructor() {
    super('integrations/unicas', { accountScoped: true });
  }

  getMemberships(contactId) {
    return axios.get(`${this.url}/memberships`, {
      params: { contact_id: contactId },
    });
  }
}

export default new UnicasAPI();
