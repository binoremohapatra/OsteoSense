const mongoose = require('mongoose');
require('./src/config/env');
mongoose.connect(process.env.MONGODB_URI).then(async () => {
  const Screening = require('./src/models/Screening');
  const docs = await Screening.find();
  console.log('Total Screenings Found: ' + docs.length);
  console.log(JSON.stringify(docs.slice(-3), null, 2));
  process.exit(0);
}).catch(console.error);
