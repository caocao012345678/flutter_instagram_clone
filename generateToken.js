const fs = require('fs');
const path = require('path');
const { GoogleAuth } = require('google-auth-library');

const auth = new GoogleAuth({
    keyFile: './ServiceAccount.json',
    scopes: 'https://www.googleapis.com/auth/firebase.messaging',
});

async function getAccessToken() {
    const client = await auth.getClient();
    const accessToken = await client.getAccessToken();
    return accessToken.token;
}

getAccessToken()
    .then(token => {
        console.log('Generated OAuth2 token:', token);
        const filePath = path.join(__dirname, 'assets', 'token.txt');
        fs.mkdirSync(path.dirname(filePath), { recursive: true });
        fs.writeFile(filePath, token, (err) => {
            if (err) {
                console.error('Error writing token to file:', err);
            } else {
                console.log('Token successfully saved to assets/token.txt');
            }
        });
    })
    .catch(error => {
        console.error('Error generating token:', error);
    });
