# frozen_string_literal: true

$:.unshift '../../lib'

require 'callnumber_models'

class CallnumberController < ApplicationController

  def index

  end

  def first
    callnumber = params[:callnumber]
    @base_cnrq = CallnumberRangeQuery.new(callnumber: callnumber)
    @crnq      = @base_cnrq.clone_to(FirstPage, key: @base_cnrq.callnumber)
    render :list
  end

  def next
    callnumber = params[:callnumber]
    page       = params[:page].to_i
    key        = params[:key]

    if page == 0
      redirect_to(action: :first, params: {callnumber: callnumber})
    else
      c     = CallnumberRangeQuery.new(callnumber: callnumber, key: key, page: page)
      @crnq = c.clone_to(NextPage)
      render :list
    end

  end

  def previous
    callnumber = params[:callnumber]
    page       = params[:page].to_i
    key        = params[:key]
    if page == 0
      redirect_to(action: :first, params: {callnumber: callnumber})
    else
      c          = CallnumberRangeQuery.new(callnumber: callnumber, key: key, page: page)
    @crnq      = c.clone_to(PreviousPage)
    render :list
    end
  end
end
