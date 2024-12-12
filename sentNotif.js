const axios = require('axios')

const token = '';
const url = 'https://fcm.googleapis.com/v1/projects/testvisa-6edb9/messages:send';

const messagePayload = {
    message: {
        topic: "All_devices",
        notification:{
            title: "Broadcast Notification",
            body: "This message is sent to all devices!"
        },
        android:{
            priority:"high",
            notification:{
                channel_id:"high_importance_channel"
            }
        }
    }
};
const headers={
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
};

axios.post(url,messagePayload,{headers}).then(response=>{console.log('Message sent successfully:',response.data);
}).catch(error=>{console.error('Error sending message:',error.response ? error.response.data : error.message);
});