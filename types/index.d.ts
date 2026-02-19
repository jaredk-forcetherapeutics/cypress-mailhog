/// <reference types="cypress" />
declare namespace Cypress {
  interface EndToEndConfigOptions {
    mailHogUrl?: string;
    mailHogAuth?: {user: string, pass: string};
  }
  interface Chainable {
    /**
     * Makes an HTTP request to the MailHog API with automatic URL construction and authentication.
     *
     * This helper function retrieves the MailHog base URL and authentication credentials from
     * Cypress environment variables, constructs the full API URL, and executes the HTTP request
     * with proper authentication.
     * @param path - The API endpoint path (e.g., "/v2/messages" or "/v1/messages").
     * Will be prefixed with "api" and combined with the mailHogUrl base URL.
     * @param options - Additional options to pass to cy.request().
     * Common options include method, body, headers, timeout, failOnStatusCode, log, etc.
     * @returns A Cypress chainable that yields the HTTP response object.
     * @requires Environment variable `mailHogUrl` - The base URL of the MailHog server (e.g., "http://localhost:8025")
     * @requires Environment variable `mailHogAuth` (optional) - Pre-configured auth object with {user, pass}
     * @requires Environment variable `mailHogUsername` (optional) - Username for basic authentication
     * @requires Environment variable `mailHogPassword` (optional) - Password for basic authentication
     *
    */
    mhRequest(
      path: string,
      options?: Partial<Cypress.RequestOptions>,
    ): Chainable<Cypress.Response<any>>;
    
    /**
     * Fetches messages from MailHog with retryability.
     * @param fetcher - Function that returns a chainable yielding emails
     * @param filter - The filter to apply to fetched emails
     * @param limit - Maximum number of emails to fetch
     * @param options - Request options
     * @returns {Cypress.Promise<any>} The filtered emails
    */
    mhRetryFetchMessages(
      fetcher: (limit: number) => Chainable<mailhog.Item[]>,
      filter: (mails: mailhog.Item[]) => mailhog.Item[],
      limit?: number,
      options?: { timeout?: number },
    ): Chainable<mailhog.Item[]>;
    mhGetJimMode(): Chainable<boolean>;
    mhSetJimMode(enabled: boolean): Chainable<Cypress.Response<any>>;
    mhDeleteAll(
      options?: Partial<Timeoutable>,
    ): Chainable<Cypress.Response<any>>;
    mhGetAllMails(
      limit?: number,
      options?: Partial<Timeoutable>,
    ): Chainable<mailhog.Item[]>;
    mhFirst(): Chainable<mailhog.Item>;
    mhGetMailsBySubject(
      subject: string,
      limit?: number,
      options?: Partial<Timeoutable>,
    ): Chainable<mailhog.Item[]>;
    mhGetMailsByRecipient(
      recipient: string,
      limit?: number,
      options?: Partial<Timeoutable>,
    ): Chainable<mailhog.Item[]>;
    mhGetMailsBySender(
      from: string,
      limit?: number,
      options?: Partial<Timeoutable>,
    ): Chainable<mailhog.Item[]>;
    mhSearchMails(
      kind: mailhog.SearchKind,
      query: string,
      limit?: number,
      options?: Partial<Timeoutable>,
    ): Chainable<mailhog.Item[]>;
    mhFilterBySubject(subject: string): Chainable<mailhog.Item[]>;
    mhFilterByRecipient(recipient: string): Chainable<mailhog.Item[]>;
    mhFilterBySender(from: string): Chainable<mailhog.Item[]>;
    mhGetSubject(): Chainable<string>;
    mhGetBody(): Chainable<string>;
    mhGetSender(): Chainable<string>;
    mhGetRecipients(): Chainable<string[]>;
    mhGetAttachments(): Chainable<string[]>;
    mhHasMailWithSubject(subject: string): Chainable;
    mhHasMailFrom(from: string): Chainable;
    mhHasMailTo(recipient: string): Chainable;
    mhWaitForMails(moreMailsThen?: number): Chainable;
  }
}

declare namespace mailhog {
  type SearchKind = "from" | "to" | "containing";

  interface Messages {
    total: number;
    count: number;
    start: number;
    items: Item[];
  }

  interface Item {
    ID: string;
    From: From;
    To: From[];
    Content: Content;
    Created: string;
    MIME: MimeParts | null;
    Raw: Raw;
  }

  interface Content {
    Headers: Headers;
    Body: string;
    Size: number;
    MIME: MimeParts | null;
  }

  interface Headers {
    [key: string]: string[];
  }

  interface From {
    Relays: null;
    Mailbox: string;
    Domain: string;
    Params: string;
  }

  interface Raw {
    From: string;
    To: string[];
    Data: string;
    Helo: string;
  }

  interface MimeParts {
    Parts: Content[];
  }
}
