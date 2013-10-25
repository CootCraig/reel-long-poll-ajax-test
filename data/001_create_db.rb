# bundle exec sequel -m . jdbc:sqlite:testlog.db
# bundle exec sequel -m . "jdbc:sqlserver://localhost;database=reeltest;user=sa;password=banana"
# bundle exec sequel -m . "jdbc:sqlserver://gcs2;database=craig;user=sa;password=mushroom;"
#
Sequel.migration do
  change do
    create_table(:longpolltestlogs) do
      primary_key :id
      String :source, :null=>false
      Integer :channel
      Integer :counter
      DateTime :updated_at
      DateTime :created_at
    end
  end
end

