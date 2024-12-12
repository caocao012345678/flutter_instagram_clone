const axios = require('axios')

const token = 'ya29.c.c0ASRK0GZh2qEF3N7KpTTy3iH0zcdgn4QGrKaT3Skm2xD5WAppBM9Sf7U7ZzaHH5DHD--SPOBGQtOKOVhw-yMf8Ei6iIWH3SvJYjEHHFQyFFk7G7wPeiMfaXpivXdTiiWtJGtyjzcO7aTKX9D1wOzBEY0UqSbbNaedMg94c4ideVZgJTOWD6_T-qJGy6hsHE9o2Q1WCbemya5QwZfkD0ZN6ICLYtiZtwCbmNqboi0UhhOr7toUMYdduak7WPWmjBqhZNms6fUa1CCAOFg13BaZwDj3hdjdtagoUQlRXTuMFoexiwkWJ0laMygsouW62BbzU3a_XusYiH4D7y8SBjphSEWIyonSSKQzqIaKG_a9p8RqO5VRrBWzN6oG384Pjfnicw07sVwhuF2UM1_-99Q10gXUVWsjmS5JmS8gYBYYregZa-S9-kj3Q5l3cJRboS--RR1xwSJYp6QjQMcJfRcBlBJs55y8fq4QoJ2yhfVSJ6IUjxacVxhZjop1274rQY6ghdcm3ymjwz9sveIdlJi_3JMh1BQUQxn-_XRuyqhW9zgd0dweIw0S0tXYyOjkwF6bjS0lh2iX9R75jI6n6Fdi9ZUzkq55_mbx_hyBScUnwXavdgOar--_sb_02-un9sOvz804MMrSUaSuipVsQhpu1ZR5WzZ8M00Q5JFZFatRot0QXFId_rgerQyjyQ2wWQX7Qp2rf9x4rVweUMmcZ-vI_cb-vZxuXbMWVR0QtWIvqIn8fvmRqjbzwMnfgljnYRku68J-5tfMd2i6tXMSQY2BFBbfOIe7m7httjSmgV-iiOwWjjlYr8hwOaZvvReWsWV9fb8QweVqhSoZeqS9tWafzrMcVWMFtYdR8ovJoFvUV1RhJorl5VnJ86w3xrVnUmb5Yg0lxUgYydk_dnUaSu7_0jlrY4-bmMvoepqt8of_9tyJmf774howpgsl2mpukjJ31UOok1vgp41s1hmkWYltMh_Rl9gMpckq0bMI_rsfZgoaMfUsylJxi9c';
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