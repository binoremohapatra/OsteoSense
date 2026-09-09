'use strict';

const mongoose = require('mongoose');

const { Schema } = mongoose;

const patientSchema = new Schema(
  {
    agentId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    age: {
      type: Number,
      required: true,
      min: 0,
      max: 150,
    },
    gender: {
      type: String,
      enum: ['male', 'female', 'other'],
      required: true,
    },
    contact: {
      type: String,
      trim: true,
    },
    village: {
      type: String,
      trim: true,
    },
    address: {
      type: String,
      trim: true,
    },
    occupation: {
      type: String,
      trim: true,
    },
    height: {
      type: Number,
    },
    weight: {
      type: Number,
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_doc, ret) => {
        const idStr = ret._id ? ret._id.toString() : '';
        ret.id = idStr;
        ret._id = idStr;
        ret.server_id = idStr;
        ret.serverId = idStr;
        delete ret.__v;
        return ret;
      },
    },
  }
);

patientSchema.index({ agentId: 1, isDeleted: 1, createdAt: -1 });
patientSchema.index({ name: 'text', village: 'text' });

module.exports = mongoose.model('Patient', patientSchema);
