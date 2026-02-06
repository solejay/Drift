import Vapor

// MARK: - Plaid Error Response

struct PlaidErrorResponse: Content {
    let error_type: String
    let error_code: String
    let error_message: String
    let display_message: String?
}

// Note: PlaidWebhookRequest and PlaidWebhookError are defined in PlaidController.swift
