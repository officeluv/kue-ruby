require 'spec_helper'

describe KueRuby do
  let(:kue_ruby) { KueRuby.new(redis: Redis.new) }

  it 'has a version number' do
    expect(KueRuby::VERSION).not_to be nil
  end

  describe '#initialize' do
    it 'rejects with no redis' do
      begin
        KueRuby.new(prefix: 'p')
      rescue ArgumentError => e
        expect(e.class).to eq(ArgumentError)
      end
    end

    it 'has a redis connection' do
      expect(kue_ruby.redis.class).to eq(Redis)
    end

    it 'has a prefix' do
      expect(kue_ruby.prefix).to eq('q')
    end

    it 'respects a prefix' do
      kue = KueRuby.new(redis: Redis.new, prefix: 'p')
      expect(kue.prefix).to eq('p')
    end
  end

  describe '#create_fifo' do
    it 'returns fifo id' do
      expect(kue_ruby.create_fifo(1)).to eq('01|1')
      expect(kue_ruby.create_fifo(22)).to eq('02|22')
    end
  end

  describe '#create_job' do
    it 'rejects with no data' do
      options = { type: 'foo' }
      begin
        kue_ruby.create_job(options)
      rescue ArgumentError => e
        expect(e.class).to eq(ArgumentError)
      end
    end

    it 'rejects with no type' do
      options = { data: { bar: 2 } }
      begin
        kue_ruby.create_job(options)
      rescue ArgumentError => e
        expect(e.class).to eq(ArgumentError)
      end
    end

    it 'returns new KueJob' do
      options = { data: { bar: 2 }, type: 'foo' }
      resp = kue_ruby.create_job(options)
      expect(resp.class).to eq(KueRuby::KueJob)
    end

    it 'set values on returned KueJob' do
      options = { data: { bar: 2 }, type: 'foo' }
      resp = kue_ruby.create_job(options)
      expect(resp.zid.class).to eq(String)
      expect(resp.id.class).to eq(Fixnum)
      expect(resp.data).to eq(bar: 2)
      expect(resp.type).to eq('foo')
      expect(resp.state).to eq('inactive')
    end
  end
end

describe KueRuby::KueJob do
  let(:kue_job) { KueRuby::KueJob.new }

  it 'has a value' do
    expect(kue_job).not_to be nil
  end

  it 'has an id attr' do
    kue_job.id = 1
    expect(kue_job.id).not_to be nil
  end
end
