require "./spec_helper"

describe GodsMatchmaking do
  it "initializes" do
    GodsMatchmaking::Bot.new("token", 69, 0, 1)
  end
end

describe GodsMatchmaking::Srcom do
  runs = [
    Run.new("0", "", 10.seconds, "x", ["a"], "", "verified", "", nil, nil),
    Run.new("1", "", 11.seconds, "x", ["b"], "", "verified", "", nil, nil),
    Run.new("2", "", 6.seconds, "x", ["c"], "", "verified", "", nil, nil)
  ]


  describe "#rank_runs" do
    it "sorts correctly without multiple runs from the same player" do
      srcom = GodsMatchmaking::Srcom.new(SrcomApi.new(""), runs, [Category.new("cat", "x")], Discord::Snowflake.new(0))
      srcom.rank_runs
      srcom.ranked_runs["x"].should eq [runs[2], runs[0], runs[1]]
    end

    runs << Run.new("3", "", 5.seconds, "x", ["a"], "", "verified", "", nil, nil)
    it "sorts correctly with multiple runs from the same player" do
      srcom = GodsMatchmaking::Srcom.new(SrcomApi.new(""), runs, [Category.new("cat", "x")], Discord::Snowflake.new(0))
      srcom.rank_runs
      srcom.ranked_runs["x"].should eq [runs[3], runs[2], runs[1]]
    end

    runs = [
      Run.new("0", "", 10.seconds, "x", ["a", "b"], "", "verified", "", nil, nil),
      Run.new("1", "", 5.seconds, "x", ["c", "d"], "", "verified", "", nil, nil),
      Run.new("2", "", 7.seconds, "x", ["e", "f"], "", "verified", "", nil, nil),
    ]
    it "sorts co-op runs correctly" do
      srcom = GodsMatchmaking::Srcom.new(SrcomApi.new(""), runs, [Category.new("cat", "x")], Discord::Snowflake.new(0))
      srcom.rank_runs
      srcom.ranked_runs["x"].should eq [runs[1], runs[2], runs[0]]
    end

    runs = [
      Run.new("0", "", 10.seconds, "x", ["a", "b"], "", "verified", "", nil, nil),
      Run.new("1", "", 5.seconds, "x", ["c", "d"], "", "verified", "", nil, nil),
      Run.new("2", "", 7.seconds, "x", ["a", "b"], "", "verified", "", nil, nil),
    ]
    it "declares runs obsolete with same players, same order" do
      srcom = GodsMatchmaking::Srcom.new(SrcomApi.new(""), runs, [Category.new("cat", "x")], Discord::Snowflake.new(0))
      srcom.rank_runs
      srcom.ranked_runs["x"].should eq [runs[1], runs[2]]
    end

    runs = [
      Run.new("0", "", 10.seconds, "x", ["a", "b"], "", "verified", "", nil, nil),
      Run.new("1", "", 5.seconds, "x", ["c", "d"], "", "verified", "", nil, nil),
      Run.new("2", "", 7.seconds, "x", ["b", "a"], "", "verified", "", nil, nil),
    ]
    it "declares runs obsolete with same players, different order" do
      srcom = GodsMatchmaking::Srcom.new(SrcomApi.new(""), runs, [Category.new("cat", "x")], Discord::Snowflake.new(0))
      srcom.rank_runs
      srcom.ranked_runs["x"].should eq [runs[1], runs[2]]
    end

    runs = [
      Run.new("0", "", 10.seconds, "x", ["a", "b"], "", "verified", "", nil, nil),
      Run.new("1", "", 5.seconds, "x", ["b", "d"], "", "verified", "", nil, nil),
      Run.new("2", "", 7.seconds, "x", ["a", "c"], "", "verified", "", nil, nil),
    ]
    it "declares runs obsolete with same players, different runs" do
      srcom = GodsMatchmaking::Srcom.new(SrcomApi.new(""), runs, [Category.new("cat", "x")], Discord::Snowflake.new(0))
      srcom.rank_runs
      srcom.ranked_runs["x"].should eq [runs[1], runs[2]]
    end

    runs = [
      Run.new("0", "", 10.seconds, "x", ["a", "b"], "", "verified", "", nil, nil),
      Run.new("1", "", 5.seconds, "x", ["c", "d"], "", "verified", "", nil, nil),
      Run.new("2", "", 7.seconds, "x", ["a", "c"], "", "verified", "", nil, nil),
    ]
    it "doesn't declare runs obsolete where only one has another run" do
      srcom = GodsMatchmaking::Srcom.new(SrcomApi.new(""), runs, [Category.new("cat", "x")], Discord::Snowflake.new(0))
      srcom.rank_runs
      srcom.ranked_runs["x"].should eq [runs[1], runs[2], runs[0]]
    end

    runs = [
      Run.new("0", "", 10.seconds, "x", ["b", "c"], "", "verified", "", nil, nil),
      Run.new("1", "", 5.seconds, "x", ["a", "d"], "", "verified", "", nil, nil),
      Run.new("2", "", 7.seconds, "x", ["a", "b"], "", "verified", "", nil, nil),
    ]
    it "doesn't declare runs obsolete where only one has a faster run" do
      srcom = GodsMatchmaking::Srcom.new(SrcomApi.new(""), runs, [Category.new("cat", "x")], Discord::Snowflake.new(0))
      srcom.rank_runs
      srcom.ranked_runs["x"].should eq [runs[1], runs[2], runs[0]]
    end
  end
end
