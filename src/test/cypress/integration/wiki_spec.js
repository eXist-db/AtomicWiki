/* global cy */
/// <reference types="cypress" />

context('Atomic Wiki', () => {
  beforeEach(() => {
    cy.visit('/atomic-wiki/')
  })

  describe('landing page', () => {
    it('should have welcome message', () => {
      cy.title('Atomic Wiki')
      cy.get('body')
        .contains('Welcome to Atomic Wiki')
    })
  })

 // TODO enable more sensible selectors in html
  describe('accounts' , () => {
    it('should allow UI login', () => {
      cy.get('.nav.navbar-right > :nth-child(1) > a')
        .click().contains('Login')
      cy.get(':nth-child(1) > .col-md-12 > .form-control')
        .type('editor')
      cy.get(':nth-child(2) > .col-md-12 > .form-control')
        .type('editor')
      cy.get('.form > .modal-footer > .btn')
        .click()
      cy.get('#user')
        .contains('editor')
    })
  })

  // TODO follow article links

  // TODO check navbar links

  // TODO edit article

})
