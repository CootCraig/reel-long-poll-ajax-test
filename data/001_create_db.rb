# bundle exec sequel -m . jdbc:sqlite:testlog.db
# bundle exec sequel -m . "jdbc:sqlserver://localhost;database=reeltest;user=sa;password=banana"
#
Sequel.migration do
  change do
    create_table(:testlog) do
      primary_key :id
      String :source, :null=>false
      Integer :channel
      Integer :counter
    end
  end
end

