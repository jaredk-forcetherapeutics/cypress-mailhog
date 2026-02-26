# cypress-mailhog

A collection of useful Cypress commands for MailHog 🐗.

This package supports TypeScript out of the box.

### Setup

Install this package:

```bash
# npm
npm install --save-dev cypress-mailhog

# yarn
yarn add --dev cypress-mailhog

# pnpm
pnpm add -D cypress-mailhog
```

Include this package into your Cypress command file:

```JavaScript
// cypress/support/commands
import 'cypress-mailhog';
```

Add the base url of your MailHog installation in the `e2e` block of your `cypress.config.ts` / `cypress.config.js`:

```typescript
export default defineConfig({
  projectId: "****",
  env: {
    mailHogUrl: "http://localhost:8090/",
  },
});
```

### MailHog authentication (Basic Auth)

If your MailHog instance uses authentication, add `mailHogAuth` to your cypress `env` config:

```typescript
export default defineConfig({
  env: {
    mailHogAuth: { user: "mailhog username", pass: "mailhog password" },
  },
});
```

or add `mailHogUsername` and `mailHogPassword` in cypress env config:

```typescript
export default defineConfig({
  env: {
    mailHogUsername: "mailhog username",
    mailHogPassword: "mailhog password",
  },
});
```

**Note:** This package uses the new `cy.env()` API (introduced in Cypress 15.10.0) to securely access authentication credentials. The deprecated `Cypress.env()` API is no longer used.

## Commands

### Mail Collection

#### mhGetAllMails( limit=50, options={timeout=defaultCommandTimeout} )

Yields an array of all the mails stored in MailHog. This retries automatically until mails are found (or until timeout is reached).

```JavaScript
cy
  .mhGetAllMails()
  .should('have.length', 1);
```

#### mhGetMailsBySubject( subject, limit=50, options={timeout=defaultCommandTimeout} )

Fetches all mails from MailHog and yields an array of all mails with given subject. This retries automatically until mails are found (or until timeout is reached).

```JavaScript
cy
  .mhGetMailsBySubject('My Subject')
  .should('have.length', 1);
```

#### mhGetMailsBySender( from, limit=50, options={timeout=defaultCommandTimeout} )

Fetches all mails from MailHog and yields an array of all mails with given sender. This retries automatically until mails are found (or until timeout is reached).

```JavaScript
cy
  .mhGetMailsBySender('sender@example.com')
  .should('have.length', 1);
```

#### mhGetMailsByRecipient( recipient, limit=50 )

Fetches all mails from MailHog and yields an array of all mails with given recipient.

```JavaScript
cy
  .mhGetMailsByRecipient('recipient@example.com')
  .should('have.length', 1);
```

#### mhFirst()

Yields the first mail of the loaded selection.

```JavaScript
cy
  .mhGetAllMails()
  .should('have.length', 1)
  .mhFirst();
```

#### mhDeleteAll(options={timeout=requestTimeout})

Deletes all stored mails from MailHog.

```JavaScript
cy.mhDeleteAll();

```

### Mail Searching

#### mhSearchMails( kind, query, limit=50, options={timeout=defaultCommandTimeout} )

Yields an array of mails matching the search query. This retries automatically until mails are found (or until timeout is reached).

Possible search kinds are `from` (sender), `to` (recipient) or `containing` (subject).

```JavaScript
cy
  .mhSearchMails('containing', 'My favorite subject')
  .should('have.length', 1)
  .mhFirst();

```

### Collection Filtering 🪮

**Note:** the below described filter functions can be chained together to build complex filters. They are currently not automatically retrying. So make sure to either wait a certain time before fetching your mails or to implement you own re-try logic.

#### mhFilterBySubject( subject )

Filters the current mails in context by subject and returns the filtered mail list.

```JavaScript
cy
  .mhGetMailsBySender('sender@example.com')
  .mhFilterBySubject('My Subject')
  .should('have.length', 1);
```

#### mhFilterByRecipient( recipient )

Filters the current mails in context by recipient and returns the filtered mail list.

```JavaScript
cy
  .mhGetMailsBySender('sender@example.com')
  .mhFilterByRecipient('recipient@example.com')
  .should('have.length', 1);
```

#### mhFilterBySender( sender )

Filters the current mails in context by sender and returns the filtered mail list.

```JavaScript
cy
  .mhGetMailsByRecipient('recipient@example.com')
  .mhFilterBySender('sender@example.com')
  .should('have.length', 1);
```

#### Chaining Filters

Filters can be infinitely chained together.

```JavaScript
cy
  .mhGetAllMails()
  .mhFilterBySubject('My Subject')
  .mhFilterByRecipient('recipient@example.com')
  .mhFilterBySender('sender@example.com')
  .should('have.length', 1);
```

### Handling a Single Mail ✉️

#### mhGetSubject()

Yields the subject of the current mail.

```JavaScript
cy
  .mhGetAllMails()
  .should('have.length', 1)
  .mhFirst()
  .mhGetSubject()
  .should('eq', 'My Mails Subject');
```

#### mhGetBody()

Yields the body of the current mail.

```JavaScript
cy
  .mhGetAllMails()
  .should('have.length', 1)
  .mhFirst()
  .mhGetBody()
  .should('contain', 'Part of the Message Body');
```

#### mhGetSender()

Yields the sender of the current mail.

```JavaScript
cy
  .mhGetAllMails()
  .should('have.length', 1)
  .mhFirst()
  .mhGetSender()
  .should('eq', 'sender@example.com');
```

#### mhGetRecipients()

Yields the recipient of the current mail.

```JavaScript
cy
  .mhGetAllMails()
  .should('have.length', 1)
  .mhFirst()
  .mhGetRecipients()
  .should('contain', 'recipient@example.com');
```

#### mhGetAttachments()

Yields the list of all file names of the attachments of the current mail.

```JavaScript
cy
  .mhGetAllMails()
  .should('have.length', 1)
  .mhFirst()
  .mhGetAttachments()
  .should('have.length', 2)
  .should('include', 'sample.pdf');
```

### Asserting the Mail Collection 🔍

#### mhHasMailWithSubject( subject )

Asserts if there is a mail with given subject.

```JavaScript
cy.mhHasMailWithSubject('My Subject');
```

#### mhHasMailFrom( from )

Asserts if there is a mail from given sender.

```JavaScript
cy.mhHasMailFrom('sender@example.com');
```

#### mhHasMailTo( recipient )

Asserts if there is a mail to given recipient (looks for "To", "CC" and "BCC").

```JavaScript
cy.mhHasMailTo('recipient@example.com');
```

### Helper Functions ⚙️

#### mhWaitForMails( moreMailsThen = 0 )

Waits until more then <`moreMailsThen`> mails are available on MailHog.
This is especially useful when using the `mhFilterBy<X>` functions, since they do not support automatic retrying.

```JavaScript
// this waits until there are at least 10 mails on MailHog
cy
  .mhWaitForMails(9)
  .mhGetAllMails()
  .mhFilterBySender("sender-10@example.com")
  .should("have.length", 1);
```

### Jim Chaos Monkey 🐵

#### mhGetJimMode()

Returns if Jim is enabled / disabled.

```JavaScript
cy
  .mhGetJimMode()
  .should('eq', true);
```

#### mhSetJimMode( enabled )

Enables / Disables Jim chaos monkey.

```JavaScript
cy
  .mhSetJimMode(true)
  .mhGetJimMode()
  .should('eq', true);
```

## Package Development

### Building the Package

This package is written in TypeScript and must be compiled before use.

```bash
# Compile TypeScript to JavaScript
yarn build
```

The compiled output is stored in `dist/`.

**Important:** When publishing to npm, the `prepublishOnly` script runs automatically and builds the package. However, for local development or testing, you must run `yarn build` first.

### Start Local Test Server

Navigate into the `test-server` directory.

```bash
cd ./test-server/
```

Run all tests inside the `test-server` devcontainers.

```bash
yarn cypress:ci
```

Install Node.js dependencies (for Cypress tests only).

```bash
yarn # or npm install
```

**Note:** You do NOT need PHP or Composer installed on your host machine. PHP dependencies are installed automatically inside the Docker container.

Start docker services.

```bash
docker-compose up
```

**First-time startup:** The web container will automatically install PHP dependencies via Composer. This takes 15-30 seconds. Wait for the startup to complete.

Verify services are accessible:

- Test page: [http://localhost:3000/cypress-mh-tests/](http://localhost:3000/cypress-mh-tests/)
- MailHog UI: [http://localhost:8090/](http://localhost:8090/)

**Troubleshooting:** If services don't start or localhost:3000 refuses connection, see `test-server/README.md` for detailed troubleshooting steps.

Open the Cypress testclient.

```bash
yarn cypress:open
```

### Development Helper Scripts

The `test-server/` directory includes helper scripts for common tasks:

```bash
# Start services and verify health
./dev.sh start

# Start services, verify health, and remove orphaned containers
./dev.sh start --remove-orphans

# Check service status
./dev.sh status

# View logs
./dev.sh logs

# Access container shell
./dev.sh shell

# Run composer commands inside container
./dev.sh composer update
```

See `test-server/README.md` for complete documentation and troubleshooting guide.
