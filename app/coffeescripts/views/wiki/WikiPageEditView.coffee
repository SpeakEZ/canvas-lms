define [
  'jquery'
  'underscore'
  'Backbone'
  'wikiSidebar'
  'jst/wiki/WikiPageEdit'
  'compiled/views/ValidatedFormView'
  'compiled/views/wiki/WikiPageDeleteDialog'
  'i18n!pages'
  'compiled/tinymce'
  'tinymce.editor_box'
], ($, _, Backbone, wikiSidebar, template, ValidatedFormView, WikiPageDeleteDialog, I18n) ->

  class WikiPageEditView extends ValidatedFormView
    @mixin
      els:
        '[name="wiki_page[body]"]': '$wikiPageBody'

      events:
        'click a.switch_views': 'switchViews'
        'click .delete_page': 'deleteWikiPage'
        'click .form-actions .cancel': 'cancel'

    template: template
    className: "form-horizontal edit-form validated-form-view"
    dontRenableAfterSaveSuccess: true

    @optionProperty 'wiki_pages_path'
    @optionProperty 'WIKI_RIGHTS'
    @optionProperty 'PAGE_RIGHTS'

    initialize: ->
      super
      @WIKI_RIGHTS ||= {}
      @PAGE_RIGHTS ||= {}
      @on 'success', (args) => window.location.href = @model.get('html_url')

    toJSON: ->
      json = super

      json.IS = IS =
        TEACHER_ROLE: false
        STUDENT_ROLE: false
        MEMBER_ROLE: false
        ANYONE_ROLE: false

      # rather than requiring the editing_roles to match a
      # string exactly, we check for individual editing roles
      editing_roles = json.editing_roles || ''
      editing_roles = _.map(editing_roles.split(','), (s) -> s.trim())
      if _.contains(editing_roles, 'public')
        IS.ANYONE_ROLE = true
      else if _.contains(editing_roles, 'members')
        IS.MEMBER_ROLE = true
      else if _.contains(editing_roles, 'students')
        IS.STUDENT_ROLE = true
      else
        IS.TEACHER_ROLE = true

      json.CAN =
        PUBLISH: !!@WIKI_RIGHTS.manage && json.contextName == "courses"
        DELETE: !!@PAGE_RIGHTS.delete
        EDIT_TITLE: !!@PAGE_RIGHTS.update || json.new_record
        EDIT_HIDE: !!@WIKI_RIGHTS.manage && json.contextName == "courses"
        EDIT_ROLES: !!@WIKI_RIGHTS.manage
      json.SHOW =
        OPTIONS: json.CAN.EDIT_HIDE || json.CAN.EDIT_ROLES
        COURSE_ROLES: json.contextName == "courses"
      json

    # After the page loads, ensure the that wiki sidebar gets initialized
    # correctly.
    # @api custom backbone override
    afterRender: ->
      super
      @$wikiPageBody.editorBox()
      @initWikiSidebar()

      unless @firstRender
        @firstRender = true
        $ -> $('[autofocus]:not(:focus)').eq(0).focus()

    # Initialize the wiki sidebar
    # @api private
    initWikiSidebar: ->
      unless wikiSidebar.inited
        $ ->
          wikiSidebar.init()
          $.scrollSidebar()
          wikiSidebar.attachToEditor(@$wikiPageBody).show()
      $ ->
        wikiSidebar.show()

    switchViews: (event) ->
      event?.preventDefault()
      @$wikiPageBody.editorBox('toggle')

    # Validate they entered in a title.
    # @api ValidatedFormView override
    validateFormData: (data) -> 
      errors = {}

      if data.wiki_page?.title == ''
        errors["wiki_page[title]"] = [
          {
            type: 'required'
            message: I18n.t("errors.require_title",'You must enter a title')
          }
        ]

      errors

    cancel: (event) ->
      event?.preventDefault()
      @trigger('cancel')

    deleteWikiPage: (event) ->
      event?.preventDefault()

      deleteDialog = new WikiPageDeleteDialog
        model: @model
        wiki_pages_path: @wiki_pages_path
      deleteDialog.open()
