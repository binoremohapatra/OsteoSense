'use strict';

const mongoose = require('mongoose');

const { Schema } = mongoose;

const screeningSchema = new Schema(
  {
    patientId: {
      type: Schema.Types.ObjectId,
      ref: 'Patient',
      required: true,
    },
    agentId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    screeningDate: {
      type: Date,
      default: Date.now,
      index: true,
    },
    painLevel: {
      type: Number,
      required: true,
      min: 0,
      max: 10,
    },
    stiffnessDuration: {
      type: String,
      trim: true,
    },
    swelling: {
      type: Boolean,
      default: false,
    },
    pastInjury: {
      type: String,
    },
    gaitData: {
      type: Schema.Types.Mixed,
    },
    gaitRawData: {
      type: Schema.Types.Mixed,
    },
    riskLevel: {
      type: String,
      enum: ['low', 'medium', 'high'],
      required: true,
    },
    confidence: {
      type: Number,
      min: 0,
      max: 1,
    },
    contributingFactors: {
      type: [String],
      default: [],
    },
    aiReasoning: {
      type: String,
      default: '',
    },
    doctorRecommendations: {
      type: String,
      default: '',
    },
    source: {
      type: String,
      enum: ['ml_model', 'fallback_rules'],
      required: true,
    },
    synced: {
      type: Boolean,
      default: true,
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

screeningSchema.index({ patientId: 1, screeningDate: -1 });
screeningSchema.index({ riskLevel: 1, createdAt: -1 });
screeningSchema.index({ agentId: 1, screeningDate: -1 });

module.exports = mongoose.model('Screening', screeningSchema);
